require 'rails_helper'

RSpec.describe 'Api::V1::Measurements', type: :request do
  describe 'PATCH /api/v1/measurements' do
    let_it_be(:sensor, refind: true) do
      create(:sensor, :with_valid_keys, :with_user,
             current_data: {
               'moisture_level_percent' => 10,
               'moisture_level_raw' => 3500,
               'temperature' => 18.0,
               'battery_level' => 50,
               'uptime_seconds' => 1000
             })
    end

    let(:base_body) do
      {
        data: {
          moisture_level_raw: 2675,
          uptime_seconds: 2000
        }
      }
    end

    let(:body) { base_body }

    def patch_measurement(uid: sensor.uid, secret_key: sensor.secret_key)
      patch api_v1_measurements_path, params: body.to_json, headers: {
        'CONTENT_TYPE' => 'application/json',
        'ACCEPT' => 'application/json',
        'Authorization' => ActionController::HttpAuthentication::Basic.encode_credentials(uid, secret_key)
      }
    end

    context 'with valid sensor credentials and payload' do
      context 'with all data payload' do
        it 'returns created and persists measurements' do
          patch_measurement

          expect(response).to have_http_status(:ok)
          expect(response.parsed_body).to eq('message' => 'Data saved successfully')

          expect(sensor.reload.moisture_level_percent).to eq(46.5)
          expect(sensor.moisture_level_raw).to eq(2675)
          expect(sensor.uptime_seconds).to eq(2000)
        end
      end

      context 'with only moisture data payload' do
        let(:body) { { data: { moisture_level_raw: 1515 } } }

        it 'returns unprocessable entity with the error message' do
          patch_measurement

          expect(response).to have_http_status(:unprocessable_content)
          expect(response.parsed_body['error']).to include('Missing required data: moisture_level_raw and uptime_seconds')
        end
      end
    end

    context 'with an unknown or wrong sensor uid' do
      it 'returns unauthorized' do
        patch_measurement(uid: 'GP-XXXXX-XXXXX')

        expect(response).to have_http_status(:unauthorized)
        expect(response.parsed_body).to eq('error' => 'Access denied: Invalid UID or Secret Key')
      end
    end

    context 'with an unknown or wrong secret key' do
      it 'returns unauthorized' do
        patch_measurement(secret_key: 'gpm_sk__wrong')

        expect(response).to have_http_status(:unauthorized)
        expect(response.parsed_body).to eq('error' => 'Access denied: Invalid UID or Secret Key')
      end
    end

    context 'without an Authorization header' do
      it 'returns unauthorized' do
        patch api_v1_measurements_path, params: base_body.to_json, headers: {
          'CONTENT_TYPE' => 'application/json',
          'ACCEPT' => 'application/json'
        }

        expect(response).to have_http_status(:unauthorized)
      end
    end

    context 'without a data payload' do
      let(:body) { {} }

      it 'does not save and responds with a client error' do
        expect do
          patch_measurement
        end.not_to(change { sensor.updated_at })

        expect(response).to have_http_status(:bad_request)
      end
    end

    context 'when the update raises' do
      before do
        allow_any_instance_of(Sensor).to receive(:update!).and_raise(ActiveRecord::RecordInvalid.new(sensor))
      end

      it 'returns unprocessable entity with the error message' do
        patch_measurement

        expect(response).to have_http_status(:unprocessable_content)
        expect(response.parsed_body['error']).to include('[MeasurementProcessor] Unable to process measurement data:')
      end
    end
  end
end
