require 'rails_helper'

RSpec.describe 'Users::PushSubscriptions', type: :request do
  let(:valid_params) do
    {
      push_subscription: {
        endpoint: 'https://fcm.googleapis.com/fcm/send/example',
        p256dh_key: 'BNcRdreALRFXTkOOUHK1EtK2wtaz5Ry4YfYCA_0QTpQtUbVlTLsTjro',
        auth_key: 'tBHItJI5svbpez7KI4CCXg',
        pwa: 'false'
      }
    }
  end

  describe 'POST /users/push_subscriptions' do
    context 'when not signed in' do
      it 'redirects to sign in' do
        post users_push_subscriptions_path, params: valid_params

        expect(response).to redirect_to(new_session_path)
      end
    end

    context 'when signed in' do
      with_user_signed_in :persisted_forced

      context 'when the subscription does not exist yet' do
        it 'creates a new push subscription and returns 200' do
          expect do
            post users_push_subscriptions_path, params: valid_params
          end.to change { user.push_subscriptions.count }.by(1)

          expect(response).to have_http_status(:ok)
        end

        it 'creates a PWA subscription if the pwa param is true' do
          expect do
            post users_push_subscriptions_path, params: valid_params.merge(push_subscription: { pwa: 'true' })
          end.to change { user.push_subscriptions.count }.by(1)

          expect(user.push_subscriptions.last.pwa).to be(true)
        end

        it 'stores the user_agent from the request' do
          post users_push_subscriptions_path, params: valid_params,
                                              headers: { 'HTTP_USER_AGENT' => 'TestBrowser/1.0' }

          expect(user.push_subscriptions.last.user_agent).to eq('TestBrowser/1.0')
        end
      end

      context 'when the subscription already exists' do
        let!(:existing) { create(:push_subscription, user:, **valid_params[:push_subscription]) }

        it 'does not create a duplicate' do
          expect do
            post users_push_subscriptions_path, params: valid_params
          end.not_to(change { user.push_subscriptions.count })
        end

        it 'touches the existing subscription and returns 200' do
          travel_to(1.hour.from_now) do
            expect do
              post users_push_subscriptions_path, params: valid_params
            end.to(change { existing.reload.updated_at })
          end

          expect(response).to have_http_status(:ok)
        end
      end
    end
  end
end
