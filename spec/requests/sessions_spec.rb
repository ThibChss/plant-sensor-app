require 'rails_helper'

RSpec.describe 'Sessions', type: :request do
  let_it_be(:user) { create(:user) }

  describe 'GET /session/new' do
    context 'when not signed in' do
      it 'returns success' do
        get new_session_path

        expect(response).to have_http_status(:ok)
      end
    end

    context 'when signed in' do
      before do
        post session_path, params: {
          email_address: user.email_address,
          password: user.password
        }
      end

      it 'redirects to the post-auth URL' do
        get new_session_path

        expect(response).to redirect_to(sensors_path)
      end
    end
  end

  describe 'POST /session' do
    let(:base_params) do
      { email_address: user.email_address, password: user.password }
    end
    let(:params) { base_params }

    context 'with valid credentials' do
      it 'starts a session and redirects to the sensors dashboard' do
        expect do
          post session_path, params:
        end.to change(Session, :count).by(1)

        expect(response).to redirect_to(sensors_path)

        follow_redirect!

        expect(response).to have_http_status(:ok)
      end
    end

    context 'with invalid credentials' do
      let(:params) { base_params.merge(password: 'wrong-password') }

      it 'does not create a session and redirects with an alert' do
        expect do
          post session_path, params:
        end.not_to change(Session, :count)

        expect(response).to redirect_to(new_session_path)
        expect(flash[:alert]).to eq(I18n.t('controllers.sessions.invalid_credentials'))
      end
    end
  end

  describe 'DELETE /session' do
    context 'when signed in' do
      before do
        post session_path, params: {
          email_address: user.email_address,
          password: user.password
        }
      end

      it 'ends the session and redirects to root' do
        expect do
          delete session_path
        end.to change { user.sessions.count }.by(-1)

        expect(response).to redirect_to(root_path)

        get profile_path

        expect(response).to redirect_to(new_session_path)
      end
    end

    context 'when not signed in' do
      it 'redirects to sign in before running destroy' do
        delete session_path

        expect(response).to redirect_to(new_session_path)
      end
    end
  end
end
