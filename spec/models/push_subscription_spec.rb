require 'rails_helper'

RSpec.describe PushSubscription, type: :model do
  describe 'associations' do
    it { should belong_to(:user) }
  end

  describe 'instance methods' do
    describe '#deliver' do
      subject(:deliver) { subscription.deliver(message: 'Water your plant!') }

      let(:subscription) { create(:push_subscription) }

      it 'enqueues a WebPushJob with the correct arguments' do
        expect { deliver }.to have_enqueued_job(Notifications::WebPushJob).with(
          message: 'Water your plant!',
          subscription:
        )
      end
    end
  end
end
