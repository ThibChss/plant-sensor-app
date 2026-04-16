class ProfileController < ApplicationController
  def show
    @current_user = Current.user
  end

  def update_locale
    if locale_valid? && user.update(locale: locale_param)
      redirect_to profile_path, notice: message { t('pages.profile.locale_updated_notice') }
    else
      redirect_to profile_path, alert: message { t('pages.profile.locale_update_failed_alert') }
    end
  end

  def update_push_notifications
    user.toggle!(:push_notifications_enabled)

    toast_now(:success, message { t('pages.profile.push_notifications_updated_notice') })

    render json: { enabled: user.push_notifications_enabled }
  end

  private

  def locale_param
    params[:locale]&.to_sym
  end

  def locale_valid?
    I18n.available_locales.include?(locale_param)
  end

  def user
    @user ||= Current.user
  end

  def message(&)
    super(use_locale: locale_param, &)
  end
end
