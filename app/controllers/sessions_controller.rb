class SessionsController < ApplicationController
  allow_unauthenticated_access only: %i[new create]

  before_action :set_locale_if_unauthenticated, only: %i[new create]

  rate_limit to: 10, within: 3.minutes, only: :create, with: lambda {
    redirect_to new_session_path, alert: I18n.t('controllers.sessions.try_again_later')
  }

  def new
    return unless authenticated?

    redirect_to after_authentication_url
  end

  def create
    if (user = User.authenticate_by(user_params))
      start_new_session_for user

      redirect_to after_authentication_url
    else
      redirect_to new_session_path, alert: I18n.t('controllers.sessions.invalid_credentials')
    end
  end

  def destroy
    terminate_session

    redirect_to root_path
  end

  private

  def user_params
    params.permit(:email_address, :password)
  end
end
