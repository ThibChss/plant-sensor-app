class PagesController < ApplicationController
  allow_unauthenticated_access only: :home

  before_action :set_locale_if_unauthenticated, only: :home

  def home
  end

  def profile
    @current_user = Current.user
  end

  def update_locale
    if locale_valid? && Current.user.update(locale: locale_param)
      redirect_to profile_path, notice: t('pages.profile.locale_updated_notice')
    else
      redirect_to profile_path, alert: t('pages.profile.locale_update_failed_alert')
    end
  end

  private

  def locale_param
    params[:locale].to_sym
  end

  def locale_valid?
    I18n.available_locales.include?(locale_param)
  end
end
