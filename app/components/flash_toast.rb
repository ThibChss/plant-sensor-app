# frozen_string_literal: true

module Components
  class FlashToast < Components::Base
    # :viewport — fixed to browser window (real mobile / full-screen)
    # :device_frame — absolute to the layout’s relative phone chrome (desktop preview)
    def initialize(flash:, position: :viewport)
      @flash = flash
      @position = position.to_s.inquiry
      super()
    end

    def view_template
      return if flash_entries.empty?

      flash_container do
        flash_entries.each { |type, msg| render Components::Toast.new(type:, message: msg) }
      end
    end

    private

    def flash_container(&)
      div(class: "pointer-events-none #{flash_position} inset-x-0 top-0 z-[100] flex flex-col items-center gap-3
                  px-6 pt-[max(1.5rem,env(safe-area-inset-top))]", aria: { live: 'polite' }, &)
    end

    def flash_entries
      @flash_entries ||= @flash.filter_map do |type, msg|
        [type, msg] if msg.present?
      end
    end

    def flash_position
      @position.device_frame? ? 'absolute' : 'fixed'
    end
  end
end
