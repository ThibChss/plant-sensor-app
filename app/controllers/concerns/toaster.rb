module Toaster
  extend ActiveSupport::Concern

  FLASH_ID = 'flash'.freeze
  FLASH_PARTIAL = 'shared/flash'.freeze

  private_constant :FLASH_ID, :FLASH_PARTIAL

  included do
    helper_method :render_with_toast, :render_toast, :toast_now, :toast_later
  end

  private

  def render_with_toast(toast_type, message, **kwargs)
    respond_to do |format|
      format_args(kwargs).each do |render_format, content|
        format.send(render_format) { render render_format => content }
      end

      format.turbo_stream { render_toast(toast_type, message) }
    end
  end

  def format_args(kwargs)
    {
      html: kwargs.delete(:html),
      json: kwargs.delete(:json)
    }.compact_blank
  end

  def render_toast(toast_type, message)
    toast_now(toast_type, message)

    render turbo_stream: turbo_stream.replace(
      FLASH_ID,
      partial: FLASH_PARTIAL,
      locals: {
        browser: @browser
      }
    )
  end

  def toast_now(toast_type, message)
    flash.now[toast_type] = message
  end

  def toast_later(toast_type, message)
    flash[toast_type] = message
  end
end
