require 'rails_helper'

RSpec.describe Notifications::Deliverer do
  describe '.notify!' do
    let_it_be(:user, refind: true) { create(:user) }
    let_it_be(:push_subscriptions) { create_list(:push_subscription, 2, user:) }

    let(:message) { 'Your sensor is now connected.' }
    let(:notification_type) { :sensor_connected }
    let(:flash_type) { :notice }

    subject(:notify!) do
      described_class.notify!(
        user:,
        message:,
        notification_type:,
        flash_type:,
        notifiable: nil,
        data: {}
      )
    end

    before do
      allow(Turbo::StreamsChannel).to receive(:broadcast_append_to)
      allow(ApplicationController).to receive(:render).and_return('<div>toast</div>')
    end

    context 'with an invalid notification type' do
      let(:notification_type) { :nonexistent_type }

      it 'raises DeliveryError' do
        expect { notify! }.to raise_error(
          Notifications::Deliverer::DeliveryError,
          /Invalid notification type: nonexistent_type/
        )
      end

      it 'does not create any notification record' do
        expect do
          notify!
        rescue
          nil
        end.not_to change(Notification, :count)
      end
    end

    context 'when the user is active' do
      before { user.update!(last_seen_at: 1.minute.ago) }

      it 'broadcasts a flash toast via Turbo' do
        notify!

        expect(Turbo::StreamsChannel).to have_received(:broadcast_append_to)
          .with(user, hash_including(target: :flash))
      end

      it 'creates a SensorConnected notification record' do
        expect { notify! }.to change { Notifications::SensorConnected.count }.by(1)
      end

      it 'stores via: flash, its type and the message in the notification data' do
        notify!

        expect(Notifications::SensorConnected.last.data).to include(
          'via' => 'flash',
          'message' => message,
          'flash_type' => flash_type.to_s
        )
      end

      it 'assigns the notification to the user' do
        notify!

        expect(Notifications::SensorConnected.last.user).to eq(user)
      end

      it 'does not deliver web push' do
        expect { notify! }.not_to have_enqueued_job(Notifications::WebPushJob)
      end
    end

    context 'when the user is inactive' do
      before { user.update!(last_seen_at: 3.minutes.ago) }

      context 'and push notifications are enabled' do
        it 'enqueues a WebPushJob for each subscription' do
          expect { notify! }.to have_enqueued_job(Notifications::WebPushJob).twice
        end

        it 'creates a SensorConnected notification with via: web_push' do
          expect { notify! }.to change { Notifications::SensorConnected.count }.by(1)

          expect(Notifications::SensorConnected.last.data).to include(
            'via' => 'web_push',
            'message' => message
          )
        end

        it 'does not broadcast a Turbo flash' do
          notify!

          expect(Turbo::StreamsChannel).not_to have_received(:broadcast_append_to)
        end
      end

      context 'and push notifications are disabled' do
        before { user.update!(push_notifications_enabled: false) }

        it 'falls back to in-app notification via Turbo' do
          notify!

          expect(Turbo::StreamsChannel).to have_received(:broadcast_append_to)
            .with(user, hash_including(target: :flash))
        end

        it 'creates a notification with via: flash' do
          expect { notify! }.to change { Notifications::SensorConnected.count }.by(1)

          expect(Notifications::SensorConnected.last.data).to include('via' => 'flash')
        end

        it 'does not enqueue any WebPushJob' do
          expect { notify! }.not_to have_enqueued_job(Notifications::WebPushJob)
        end
      end
    end

    context 'with a notifiable object' do
      let!(:sensor) { create(:sensor, :with_valid_keys) }

      before { user.update!(last_seen_at: 1.minute.ago) }

      it 'associates the notifiable with the notification' do
        described_class.notify!(
          user:,
          message:,
          notification_type:,
          flash_type:,
          notifiable: sensor,
          data: {}
        )

        expect(Notifications::SensorConnected.last.notifiable).to eq(sensor)
      end
    end

    context 'with extra data' do
      before { user.update!(last_seen_at: 1.minute.ago) }

      it 'merges extra data into the notification data' do
        described_class.notify!(
          user:,
          message:,
          notification_type:,
          flash_type:,
          notifiable: nil,
          data: { sensor_uid: 'GP-XXXXX-XXXXX' }
        )

        expect(Notifications::SensorConnected.last.data).to include('sensor_uid' => 'GP-XXXXX-XXXXX')
      end
    end
  end
end
