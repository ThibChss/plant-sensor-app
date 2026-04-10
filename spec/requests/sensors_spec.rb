require 'rails_helper'

RSpec.describe 'Sensors', type: :request do
  with_user_signed_in :persisted_forced

  describe 'GET /sensors' do
    context 'when not signed in' do
      with_user_signed_out

      it 'redirects to sign in' do
        get sensors_path

        expect(response).to redirect_to(new_session_path)
      end
    end

    context 'when signed in' do
      context 'when there are no sensors' do
        it 'returns success and shows the empty state' do
          get sensors_path

          expect(response).to have_http_status(:ok)
          expect(response.body).to include(I18n.t('sensors.index.empty_state'))
          expect(response.body).to include(I18n.t('sensors.index.dashboard_title'))
        end
      end

      context 'when there are sensors' do
        let(:plant) { create(:plant) }
        let!(:sensor) { create(:sensor, :with_uid_and_secret_key, user:, plant:, nickname: 'Balcony') }

        it 'lists the user sensors' do
          get sensors_path

          expect(response).to have_http_status(:ok)
          expect(response.body).to include(sensor.nickname)
          expect(response.body).to include(I18n.t('sensors.index.active_count', count: 1))
        end
      end
    end
  end
end
