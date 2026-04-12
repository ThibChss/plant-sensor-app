module Components
  module Layout
    class Frame < Components::Base
      def initialize(browser:)
        @browser = browser
      end

      def view_template(&)
        if mobile?
          mobile_frame(&)
        else
          desktop_frame(&)
        end
      end

      private

      def mobile?
        @browser.device.mobile?
      end

      def mobile_frame(&)
        body(class: 'flex h-dvh max-h-dvh flex-col overflow-hidden bg-pulse-mist antialiased no-scrollbar', data: { turbo_cache: 'reload' }, &)
      end

      def desktop_frame(&)
        body(class: 'flex min-h-screen items-center justify-center overflow-hidden bg-pulse-mist p-4 antialiased no-scrollbar', data: { turbo_cache: 'reload' }) do
          div(class: 'relative mx-auto flex h-[844px] w-[390px] flex-col overflow-hidden rounded-[3.5rem] border-[14px] border-gray-900 bg-gray-900 shadow-2xl', &)
        end
      end
    end
  end
end
