require 'rails_helper'

RSpec.describe Notifications::SensorConnected, type: :model do
  describe 'callbacks' do
    describe '#set_message' do
      let_it_be(:user) { create(:user) }
      let_it_be(:sensor) { create(:sensor, :with_valid_keys, user:) }

      context 'when a message was stored in data' do
        let(:notification) do
          described_class.new(
            user:,
            notifiable: sensor,
            data: { via: 'flash', message: 'Custom message', first_connection: true }
          )
        end

        it 'returns the stored message' do
          notification.validate

          expect(notification.message).to eq('Custom message')
        end
      end

      context 'when no message was stored in data' do
        let(:notification) do
          described_class.new(
            user:,
            notifiable: sensor,
            data: { via: 'web_push', first_connection: true }
          )
        end

        it 'returns the default i18n message with the sensor uid' do
          notification.validate

          expect(notification.message).to eq(
            I18n.t('notifications.sensor_connected.message', sensor_uid: sensor.uid)
          )
        end
      end

      context 'when the message is an empty string' do
        let(:notification) do
          described_class.new(
            user:,
            notifiable: sensor,
            data: { via: 'flash', message: '' }
          )
        end

        it 'falls back to the default i18n message' do
          notification.validate

          expect(notification.message).to eq(
            I18n.t('notifications.sensor_connected.message', sensor_uid: sensor.uid)
          )
        end
      end
    end
  end
end
