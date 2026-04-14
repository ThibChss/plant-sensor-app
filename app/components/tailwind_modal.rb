# frozen_string_literal: true

module Components
  class TailwindModal < Components::Base
    DIALOG_CLASS = 'absolute inset-0 z-50 size-auto max-h-none max-w-none overflow-y-auto bg-transparent
                    backdrop:bg-transparent shadow-none border-none outline-none'
    BACKDROP_TRANSITIONS = 'transition-opacity data-closed:opacity-0 data-enter:duration-300 data-enter:ease-out
                            data-leave:duration-200 data-leave:ease-in'
    SCROLLER_CLASS = 'flex min-h-full items-center justify-center p-8 text-center focus:outline-none'
    PANEL_CLASS = 'relative mx-auto w-full transform overflow-hidden rounded-[2.5rem] border border-white
                   bg-white/95 text-left shadow-2xl shadow-pulse-forest/10 outline-none backdrop-blur-xl
                   transition-all data-closed:translate-y-4 data-closed:opacity-0 data-enter:duration-300
                   data-enter:ease-out data-leave:duration-200 data-leave:ease-in data-closed:sm:scale-95'

    private_constant :DIALOG_CLASS, :BACKDROP_TRANSITIONS, :SCROLLER_CLASS, :PANEL_CLASS

    def initialize(id:, labelledby:, panel_max_width: 'max-w-[19rem]', backdrop_blur: 'backdrop-blur-[2px]')
      @id = id
      @labelledby = labelledby
      @panel_max_width = panel_max_width
      @backdrop_blur = backdrop_blur
    end

    def view_template(&)
      tag(:el_dialog) do
        dialog(id: @id, aria: { labelledby: @labelledby }, class: DIALOG_CLASS) do
          tag(
            :el_dialog_backdrop,
            class: "absolute inset-0 bg-pulse-forest/20 #{@backdrop_blur} #{BACKDROP_TRANSITIONS}"
          )
          div(tabindex: 0, class: SCROLLER_CLASS) do
            tag(:el_dialog_panel, class: "#{PANEL_CLASS} #{@panel_max_width}", &)
          end
        end
      end
    end
  end
end
