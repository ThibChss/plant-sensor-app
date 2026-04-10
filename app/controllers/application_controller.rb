class ApplicationController < ActionController::Base
  include Authentication

  # Only allow modern browsers supporting webp images, web push, badges, import maps, CSS nesting, and CSS :has.
  allow_browser versions: :modern

  # Changes to the importmap will invalidate the etag for HTML responses
  stale_when_importmap_changes

  before_action :set_browser, :track_navigation

  private

  def set_browser
    @browser = Browser.new(request.user_agent)
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
