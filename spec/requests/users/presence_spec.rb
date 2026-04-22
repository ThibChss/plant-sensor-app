require 'rails_helper'

RSpec.describe 'Users::Presence', type: :request do
  describe 'PATCH /users/presence' do
    context 'when not signed in' do
      it 'redirects to the sign-in page' do
        patch users_presence_path

        expect(response).to redirect_to(new_session_path)
      end
    end

    context 'when signed in' do
      with_user_signed_in :persisted_forced

      it 'returns ok' do
        patch users_presence_path

        expect(response).to have_http_status(:ok)
      end

      it 'updates last_seen_at to the current time' do
        freeze_time do
          patch users_presence_path

          expect(user.reload.last_seen_at).to eq(Time.current)
        end
      end
    end
  end
end
