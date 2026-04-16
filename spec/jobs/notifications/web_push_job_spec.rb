require 'rails_helper'

RSpec.describe Notifications::WebPushJob, type: :job do
  subject(:perform) { described_class.perform_now(message:, subscription:) }

  let(:message) { 'Water your plant!' }

  before do
    allow(WebPush).to receive(:payload_send)
  end

  context 'when the job is performed properly' do
    context 'with a PWA subscription' do
      let(:subscription) { build(:push_subscription, :pwa) }

      it 'includes the icon in the payload' do
        perform

        expect(WebPush).to have_received(:payload_send).with(
          hash_including(message: { title: 'Green Pulse', body: message, icon: '/icon.png' }.to_json)
        )
      end
    end

    context 'with a non-PWA subscription' do
      let(:subscription) { build(:push_subscription) }

      it 'does not include the icon in the payload' do
        perform

        expect(WebPush).to have_received(:payload_send).with(
          hash_including(message: { title: 'Green Pulse', body: message }.to_json)
        )
      end
    end
  end

  context 'when the job fails' do
    let_it_be(:subscription, refind: true) { create(:push_subscription) }

    before do
      allow(WebPush).to receive(:payload_send).and_raise(error)
    end

    context 'when the subscription has expired' do
      let(:error) { WebPush::ExpiredSubscription.allocate }

      it 'destroys the subscription' do
        expect { perform }.to change(PushSubscription, :count).by(-1)
      end
    end

    context 'when the subscription is invalid' do
      let(:error) { WebPush::InvalidSubscription.allocate }

      it 'destroys the subscription' do
        expect { perform }.to change(PushSubscription, :count).by(-1)
      end
    end

    context 'when a generic WebPush error occurs' do
      let(:error) { WebPush::ResponseError.allocate }

      before do
        allow(Rails.logger).to receive(:error)
      end

      it 'logs the error and does not raise' do
        expect { perform }.not_to raise_error

        expect(Rails.logger).to have_received(:error).with(/\[WebPush\] Failed to deliver/)
      end
    end
  end
end
