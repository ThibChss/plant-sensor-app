require 'rails_helper'

RSpec.describe 'Profile', type: :request do
  with_user_signed_in :persisted_forced

  describe 'GET /profile' do
    context 'when not signed in' do
      with_user_signed_out

      it 'redirects to sign in' do
        get profile_path

        expect(response).to redirect_to(new_session_path)
      end
    end

    context 'when signed in' do
      it 'returns success and displays the user profile' do
        get profile_path

        expect(response).to have_http_status(:ok)
        expect(response.body).to include(user.full_name)
        expect(response.body).to include(user.email_address)
      end
    end
  end

  describe 'PATCH /profile/update_locale' do
    context 'when signed in' do
      it 'updates the user locale and redirects to profile' do
        expect(user.locale).to eq('fr')

        patch locale_profile_path, params: { locale: 'en' }

        expect(response).to redirect_to(profile_path)
        expect(user.reload.locale).to eq('en')
      end

      it 'stores the success flash in the newly selected language' do
        patch locale_profile_path, params: { locale: 'en' }

        follow_redirect!

        expect(flash[:notice]).to eq(I18n.t('pages.profile.locale_updated_notice', locale: :en))
      end

      it 'ignores an unsupported locale' do
        patch locale_profile_path, params: { locale: 'de' }

        expect(response).to redirect_to(profile_path)
        expect(user.reload.locale).to eq('fr')
      end
    end

    context 'when not signed in' do
      with_user_signed_out

      it 'redirects to sign in' do
        patch locale_profile_path, params: { locale: 'en' }

        expect(response).to redirect_to(new_session_path)
      end
    end
  end

  describe 'PATCH /profile/update_push_notifications' do
    context 'when signed in' do
      it 'enables push notifications when currently disabled' do
        user.update!(push_notifications_enabled: false)

        expect do
          patch push_notifications_profile_path, headers: { 'Accept' => 'text/vnd.turbo-stream.html' }
        end.to change { user.reload.push_notifications_enabled }.from(false).to(true)

        expect(response).to have_http_status(:ok)
      end

      it 'disables push notifications when currently enabled' do
        user.update!(push_notifications_enabled: true)

        expect do
          patch push_notifications_profile_path, headers: { 'Accept' => 'text/vnd.turbo-stream.html' }
        end.to change { user.reload.push_notifications_enabled }.from(true).to(false)
      end
    end

    context 'when not signed in' do
      with_user_signed_out

      it 'redirects to sign in' do
        patch push_notifications_profile_path, headers: { 'Accept' => 'text/vnd.turbo-stream.html' }

        expect(response).to redirect_to(new_session_path)
      end
    end
  end
end
