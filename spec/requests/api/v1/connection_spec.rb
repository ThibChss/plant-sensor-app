require 'rails_helper'

RSpec.describe 'Api::V1::Connection', type: :request do
  describe 'PATCH /api/v1/connection' do
    let_it_be(:user)   { create(:user) }
    let_it_be(:sensor) { create(:sensor, :with_valid_keys, user:) }

    let(:body) { base_body }

    let(:base_body) do
      {
        connection: {
          sensor_uid: sensor.uid,
          secret_key: sensor.secret_key,
          paired: true
        }
      }
    end

    def patch_connection
      patch api_v1_connection_path, params: body.to_json, headers: {
        'CONTENT_TYPE' => 'application/json',
        'ACCEPT' => 'application/json'
      }
    end

    before { allow(Notifications::Deliverer).to receive(:notify!) }

    context 'with an unknown sensor uid' do
      let(:body) { base_body.deep_merge(connection: { sensor_uid: 'GP-XXXXX-XXXXX' }) }

      it 'returns unauthorized and does not notify' do
        patch_connection

        expect(response).to have_http_status(:unauthorized)
        expect(Notifications::Deliverer).not_to have_received(:notify!)
      end
    end

    context 'with a wrong secret key' do
      let(:body) { base_body.deep_merge(connection: { secret_key: 'gpm_sk__wrong' }) }

      it 'returns unauthorized and does not notify' do
        patch_connection

        expect(response).to have_http_status(:unauthorized)
        expect(Notifications::Deliverer).not_to have_received(:notify!)
      end
    end

    context 'when paired is false' do
      let(:body) { base_body.deep_merge(connection: { paired: false }) }

      it 'returns ok without notifying' do
        patch_connection

        expect(response).to have_http_status(:ok)
        expect(Notifications::Deliverer).not_to have_received(:notify!)
      end
    end

    context 'when the sensor has no user' do
      before { sensor.update!(user: nil) }

      it 'returns ok without notifying' do
        patch_connection

        expect(response).to have_http_status(:ok)
        expect(Notifications::Deliverer).not_to have_received(:notify!)
      end
    end

    context 'when paired and sensor has a user' do
      it 'returns ok' do
        patch_connection

        expect(response).to have_http_status(:ok)
      end

      context 'on the first pairing (no prior notification)' do
        it 'uses notification_type :sensor_connected and sets first_connection: true' do
          patch_connection

          expect(Notifications::Deliverer).to have_received(:notify!).with(
            user:,
            message: nil,
            notifiable: sensor,
            notification_type: :sensor_connected,
            flash_type: :notice,
            data: { first_connection: true }
          )
        end
      end

      context 'on a subsequent pairing (prior notification exists)' do
        before do
          Notifications::SensorConnected.create!(
            user:,
            notifiable: sensor,
            data: { first_connection: true, via: 'flash', message: 'connected' }
          )
        end

        it 'uses notification_type :sensor_back and sets first_connection: false' do
          patch_connection

          expect(Notifications::Deliverer).to have_received(:notify!).with(
            user:,
            message: nil,
            notifiable: sensor,
            notification_type: :sensor_back,
            flash_type: :notice,
            data: { first_connection: false }
          )
        end
      end
    end
  end
end
