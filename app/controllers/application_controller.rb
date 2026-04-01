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

  def track_navigation
    return unless request.format.html? && request.get?

    if session[:current_page] != request.original_url
      session[:previous_page] = session[:current_page]
      session[:current_page] = request.original_url
    end

    Current.previous_page = session[:previous_page]
    Current.page = session[:current_page]
  end
end
