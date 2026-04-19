require 'rails_helper'

RSpec.describe 'Sensors::Setup', type: :request do
  with_user_signed_in :persisted_forced

  let_it_be(:unclaimed_uid) { 'GP-SETUP-UNCLM' }

  describe 'GET /sensors/setup/new' do
    context 'when not signed in' do
      with_user_signed_out

      it 'redirects to the sign-in page' do
        get new_sensors_setup_path

        expect(response).to redirect_to(new_session_path)
      end
    end

    context 'when signed in' do
      context 'when accessing the setup from the navigation' do
        it 'returns success and renders the setup page' do
          get new_sensors_setup_path

          expect(response).to have_http_status(:ok)
        end
      end

      context 'when accessing the setup from a QR code' do
        context 'when the sensor is unclaimed' do
          let(:unclaimed_sensor) { create(:sensor, :with_valid_keys, user: nil, plant: nil, uid: unclaimed_uid) }

          it 'returns success and renders the setup page' do
            get new_sensors_setup_path, params: { uid: unclaimed_sensor.uid, secret_key: unclaimed_sensor.secret_key }

            expect(response).to have_http_status(:ok)
            expect(flash.now[:alert]).to be_nil
          end
        end

        context 'when the sensor is claimed' do
          let(:sensor) { create(:sensor, :with_valid_keys, user:, plant: create(:plant)) }

          it 'renders the setup page with an alert' do
            get new_sensors_setup_path, params: { uid: sensor.uid, secret_key: sensor.secret_key }

            expect(response).to have_http_status(:ok)
            expect(flash.now[:alert]).to eq(I18n.t('controllers.sensors.setup.sensor_not_found_or_paired'))
          end
        end

        context 'when the sensor does not exist' do
          it 'renders the setup page with an alert' do
            get new_sensors_setup_path, params: { uid: 'GP-NOTEX-ISTNG', secret_key: '1234567890' }

            expect(response).to have_http_status(:ok)
            expect(flash.now[:alert]).to eq(I18n.t('controllers.sensors.setup.sensor_not_found_or_paired'))
          end
        end
      end
    end
  end

  describe 'GET /sensors/setup/validate_uid' do
    let(:params) { { uid: unclaimed_uid } }

    context 'when not signed in' do
      with_user_signed_out

      it 'redirects to the sign-in page' do
        patch(validate_uid_sensors_setup_path, params:)

        expect(response).to redirect_to(new_session_path)
      end
    end

    context 'when signed in' do
      let_it_be(:unclaimed_sensor) do
        create(:sensor, :with_valid_keys, user: nil, plant: nil, uid: unclaimed_uid)
      end

      context 'when the uid is valid and the sensor is unclaimed' do
        it 'returns JSON when the uid is valid and the sensor is unclaimed' do
          patch(validate_uid_sensors_setup_path, params:)

          expect(response).to have_http_status(:ok)
          expect(response.parsed_body).to include('ok' => true)
        end
      end

      context 'when the uid has whitespace' do
        let(:params) { { uid: "  #{unclaimed_uid}  " } }

        it 'strips whitespace before validating and returns JSON' do
          patch(validate_uid_sensors_setup_path, params:)

          expect(response).to have_http_status(:ok)
          expect(response.parsed_body).to include('ok' => true)
        end
      end

      context 'when the uid format is invalid' do
        let(:params) { { uid: 'GP-SHORT' } }
        it 'returns JSON when the uid format is invalid' do
          patch(validate_uid_sensors_setup_path, params:)

          expect(response).to have_http_status(:ok)
          expect(response.parsed_body).to include('ok' => false)
          expect(response.parsed_body['message']).to include('GP-XXXXX-XXXXX')
        end
      end

      context 'when the uid is missing' do
        let(:params) { {} }

        it 'responds with bad request' do
          patch(validate_uid_sensors_setup_path, params:)

          expect(response).to have_http_status(:bad_request)
        end
      end
    end
  end

  describe 'POST /sensors/setup' do
    let_it_be(:plant) { create(:plant) }

    let(:params) do
      {
        sensor: {
          uid: unclaimed_uid,
          plant_id: plant.id,
          nickname: 'Balcony sensor',
          environment: 'indoor',
          location: 'living_room',
          moisture_threshold: 30
        }
      }
    end

    context 'when not signed in' do
      with_user_signed_out

      it 'redirects to the sign-in page' do
        post(sensors_setup_path, params:)

        expect(response).to redirect_to(new_session_path)
      end
    end

    context 'when signed in' do
      let_it_be(:unclaimed_sensor) do
        create(:sensor, :with_valid_keys, user:, plant: nil, uid: unclaimed_uid)
      end

      it 'claims the sensor, assigns the plant, and redirects home with notice' do
        expect do
          post(sensors_setup_path, params:)
        end.to change { unclaimed_sensor.reload.plant_id }.from(nil).to(plant.id)

        expect(response).to redirect_to(root_path)

        follow_redirect!

        expect(flash[:notice]).to eq(I18n.t('controllers.sensors.setup.successful'))
        expect(unclaimed_sensor.reload.nickname).to eq('Balcony sensor')
        expect(unclaimed_sensor.moisture_threshold).to eq(30)
      end

      it 'redirects to setup with alert when the sensor uid does not match an unclaimed sensor' do
        post(sensors_setup_path, params: {
               sensor: params[:sensor].merge(uid: 'GP-NOTEX-ISTNG')
             })

        expect(response).to redirect_to(new_sensors_setup_path)
        expect(flash[:alert]).to eq(I18n.t('controllers.sensors.setup.sensor_not_found'))
      end

      it 'redirects to setup with alert when the plant does not exist' do
        post sensors_setup_path, params: {
          sensor: params[:sensor].merge(plant_id: SecureRandom.uuid)
        }

        expect(response).to redirect_to(new_sensors_setup_path)
        expect(flash[:alert]).to eq(I18n.t('controllers.sensors.setup.sensor_not_found'))
      end

      it 're-renders new with unprocessable content when the location does not match the environment' do
        post sensors_setup_path, params: {
          sensor: params[:sensor].merge(environment: 'indoor', location: 'garden')
        }

        expect(response).to have_http_status(:unprocessable_content)
        expect(response.body).to include('sensor-setup-root')
      end
    end
  end
end
