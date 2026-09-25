require 'rails_helper'

RSpec.describe Notifications::MoistureLow, type: :model do
  describe 'callbacks' do
    describe '#set_message' do
      let_it_be(:user) { create(:user) }
      let_it_be(:plant) { create(:plant, name: 'Monstera') }
      let_it_be(:sensor) { create(:sensor, :with_valid_keys, user:, plant:) }

      context 'when a message was stored in data' do
        let(:notification) do
          described_class.new(
            user:,
            notifiable: sensor,
            data: { via: 'flash', message: 'Custom moisture message' }
          )
        end

        it 'returns the stored message' do
          notification.validate

          expect(notification.message).to eq('Custom moisture message')
        end
      end

      context 'when no message was stored in data' do
        let(:notification) do
          described_class.new(
            user:,
            notifiable: sensor,
            data: { via: 'web_push' }
          )
        end

        it 'returns the default i18n message with the plant name' do
          notification.validate

          expect(notification.message).to eq(
            I18n.t('notifications.moisture_low.message', plant_name: plant.name)
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
            I18n.t('notifications.moisture_low.message', plant_name: plant.name)
          )
        end
      end
    end
  end
end
