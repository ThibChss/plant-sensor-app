class RegistrationsController < ApplicationController
  allow_unauthenticated_access only: %i[new create]

  rate_limit to: 10, within: 3.minutes, only: :create,
             with: -> { redirect_to new_registration_path, alert: 'Try again later.' }

  def new
    if authenticated?
      redirect_to after_authentication_url
    else
      @user = User.new
    end
  end

  def create
    @user = User.new(user_params)

    if @user.save
      start_new_session_for @user

      redirect_to after_authentication_url
    else
      render :new, status: :unprocessable_content
    end
  end

  private

  def user_params
    params.permit(:first_name, :last_name, :email_address, :password, :password_confirmation)
  end
end
