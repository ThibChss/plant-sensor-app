require 'rails_helper'

RSpec.describe 'Registrations', type: :request do
  describe 'GET /registrations/new' do
    context 'when a user is not signed in' do
      it 'returns success' do
        get new_registration_path

        expect(response).to have_http_status(:ok)
      end
    end

    context 'when a user is signed in' do
      let(:user) { create(:user) }

      before do
        post session_path, params: {
          email_address: user.email_address,
          password: user.password
        }
      end

      it 'redirects to the post-auth URL' do
        get new_registration_path

        expect(response).to redirect_to(root_url)
      end
    end
  end

  describe 'POST /registrations' do
    let(:valid_params) do
      {
        first_name: 'Jean',
        last_name: 'Dupont',
        email_address: 'jean.dupont@example.com',
        password: 'password123',
        password_confirmation: 'password123'
      }
    end

    context 'with valid params' do
      it 'creates a user, starts a session, and redirects to root' do
        expect do
          post registrations_path, params: valid_params
        end.to change(User, :count).by(1)

        expect(response).to redirect_to(root_url)

        user = User.find_by!(email_address: 'jean.dupont@example.com')
        expect(user.sessions.count).to eq(1)
      end
    end

    context 'with invalid params' do
      let(:invalid_params) do
        valid_params.merge(email_address: 'not-email')
      end

      it 'does not create a user and responds with unprocessable content' do
        expect do
          post registrations_path, params: invalid_params
        end.not_to change(User, :count)

        expect(response).to have_http_status(:unprocessable_content)
      end
    end
  end
end
