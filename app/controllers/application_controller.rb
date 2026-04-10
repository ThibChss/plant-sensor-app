class ApplicationController < ActionController::Base
  include Authentication

  # Only allow modern browsers supporting webp images, web push, badges, import maps, CSS nesting, and CSS :has.
  allow_browser versions: :modern

  # Changes to the importmap will invalidate the etag for HTML responses
  stale_when_importmap_changes

  before_action :set_browser
  before_action :set_locale

  private

  def set_locale
    I18n.locale = validate_locale(locale)
  end

  def set_locale_if_unauthenticated
    return if authenticated? || browser_locale_invalid?

    I18n.locale = browser_locale
  end

  def locale
    @locale ||= Current.user&.locale&.to_sym
  end

  def set_browser
    @browser = Browser.new(request.user_agent)
  end

  def browser_locale
    @browser_locale ||=
      validate_locale(request.env['HTTP_ACCEPT_LANGUAGE'].to_s.scan(/[a-z]{2}/).first&.strip&.to_sym.presence) ||
      I18n.default_locale
  end

  def browser_locale_invalid?
    !I18n.available_locales.include?(browser_locale)
  end

  def message(use_locale: nil, &)
    I18n.with_locale(validate_locale(use_locale || locale), &)
  end

  def validate_locale(use_locale)
    return I18n.default_locale unless I18n.available_locales.include?(use_locale) || use_locale.blank?

    use_locale
  end

  unless Rails.env.production?
    around_action :n_plus_one_detection

    def n_plus_one_detection
      Prosopite.scan

      yield
    ensure
      Prosopite.finish
    end
  end
end
