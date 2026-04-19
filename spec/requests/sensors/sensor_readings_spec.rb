# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'Sensor readings', type: :request do
  with_user_signed_in :persisted_forced

  describe 'GET /sensors/:sensor_id/sensor_readings' do
    let_it_be(:plant) { create(:plant) }
    let_it_be(:sensor) { create(:sensor, :with_valid_keys, user:, plant:, nickname: 'Kitchen fern') }

    context 'when not signed in' do
      with_user_signed_out

      it 'redirects to sign in' do
        get sensor_readings_path(sensor)

        expect(response).to redirect_to(new_session_path)
      end
    end

    context 'when signed in' do
      context 'when the sensor does not exist' do
        it 'redirects to sensors index with an alert' do
          get sensor_readings_path('00000000-0000-0000-0000-000000000000')

          expect(response).to redirect_to(sensors_path)
          expect(flash[:alert]).to eq(I18n.t('sensors.sensor_readings.index.not_found'))
        end
      end

      context 'when the sensor belongs to another user' do
        let_it_be(:other_user) { create(:user, first_name: 'Alex', last_name: 'Rivera') }
        let_it_be(:other_sensor) { create(:sensor, :with_valid_keys, user: other_user, plant:) }

        it 'redirects to sensors index with an alert' do
          get sensor_readings_path(other_sensor)

          expect(response).to redirect_to(sensors_path)
          expect(flash[:alert]).to eq(I18n.t('sensors.sensor_readings.index.not_found'))
        end
      end

      context 'when the sensor belongs to the current user' do
        it 'returns success' do
          get sensor_readings_path(sensor)

          expect(response).to have_http_status(:ok)
          expect(response.body).to include(sensor.nickname)
          expect(response.body).to include(plant.display_name)
          expect(response.body).to include('sensor_readings_frame')
        end

        it 'accepts a range param' do
          get sensor_readings_path(sensor, range: '30d')

          expect(response).to have_http_status(:ok)
        end
      end
    end
  end
end
