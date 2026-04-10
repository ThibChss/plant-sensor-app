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

  describe 'GET /profile' do
    context 'when not signed in' do
      with_user_signed_out

      it 'redirects to sign in' do
        get profile_path

        expect(response).to redirect_to(new_session_path)
      end
    end

    context 'when signed in' do
      it 'returns success and shows the user profile' do
        get profile_path

        expect(response).to have_http_status(:ok)
        expect(response.body).to include(user.full_name)
        expect(response.body).to include(user.email_address)
      end
    end
  end

  describe 'PATCH /profile/locale' do
    context 'when signed in' do
      it 'updates the user locale and redirects to profile' do
        expect(user.locale).to eq('fr')

        patch profile_locale_path, params: { locale: 'en' }

        expect(response).to redirect_to(profile_path)
        expect(user.reload.locale).to eq('en')
      end

      it 'stores the success flash in the newly selected language, not the previous one' do
        patch profile_locale_path, params: { locale: 'en' }

        follow_redirect!

        expect(flash[:notice]).to eq(I18n.t('pages.profile.locale_updated_notice', locale: :en))
      end

      it 'ignores an unsupported locale' do
        patch profile_locale_path, params: { locale: 'de' }

        expect(response).to redirect_to(profile_path)
        expect(user.reload.locale).to eq('fr')
      end
    end

    context 'when not signed in' do
      with_user_signed_out

      it 'redirects to sign in' do
        patch profile_locale_path, params: { locale: 'en' }

        expect(response).to redirect_to(new_session_path)
      end
    end
  end
end
