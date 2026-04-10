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
    I18n.locale = I18n.available_locales.include?(locale) ? locale : I18n.default_locale
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
    @browser_locale ||= request.env['HTTP_ACCEPT_LANGUAGE'].to_s.scan(/[a-z]{2}/).first&.to_sym&.strip.presence ||
                        I18n.default_locale
  end

  def browser_locale_invalid?
    !I18n.available_locales.include?(browser_locale)
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
