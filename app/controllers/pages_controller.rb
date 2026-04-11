class PagesController < ApplicationController
  allow_unauthenticated_access only: :home

  before_action :set_locale_if_unauthenticated, only: :home

  def home
    redirect_to sensors_path if authenticated?
  end

  def profile
    @current_user = Current.user
  end

  def update_locale
    if locale_valid? && Current.user.update(locale: locale_param)
      redirect_to profile_path, notice: message { t('pages.profile.locale_updated_notice') }
    else
      redirect_to profile_path, alert: message { t('pages.profile.locale_update_failed_alert') }
    end
  end

  private

  def locale_param
    params[:locale].to_sym
  end

  def locale_valid?
    I18n.available_locales.include?(locale_param)
  end

  def message(&)
    super(use_locale: locale_param, &)
  end
end
