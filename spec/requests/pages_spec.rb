require 'rails_helper'

RSpec.describe 'Pages', type: :request do
  with_user_signed_in :persisted_forced

  describe 'GET /' do
    context 'when not signed in' do
      with_user_signed_out

      it 'returns success and shows the marketing home' do
        get root_path

        expect(response).to have_http_status(:ok)
        expect(response.body).to include('Green Pulse')
      end
    end

    context 'when signed in' do
      it 'redirects to the sensors dashboard' do
        get root_path

        expect(response).to redirect_to(sensors_path)
      end
    end
  end
end
