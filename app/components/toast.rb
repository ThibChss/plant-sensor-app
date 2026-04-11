module Components
  class Toast < Components::Base
    def initialize(type:, message:)
      @type = type.to_s.inquiry
      @message = message
    end

    def view_template
      toast_container do
        toast_icon_container
        toast_content
        toast_close_button
      end
    end

    private

    def toast_container(&)
      div(
        data: { controller: 'flash-toast' },
        class: "pointer-events-auto flex w-full max-w-[320px] -translate-y-12 items-center gap-3
                rounded-[2rem] border p-4 opacity-0 shadow-2xl shadow-pulse-forest/5 backdrop-blur-xl
                font-palanquin transition-all duration-500 ease-out
                #{toast_container_classes}",
        role: @type, &
      )
    end

    def toast_content
      div(class: 'flex-1 pr-2') do
        p(class: "#{title_text_class} text-xs font-black font-alegreya uppercase leading-tight tracking-wider") do
          toast_title
        end

        p(class: "#{body_text_class} text-[11px] font-medium leading-snug opacity-80") do
          @message
        end
      end
    end

    def toast_close_button
      button(
        type: 'button',
        data: { action: 'click->flash-toast#close' },
        class: 'text-pulse-moss/30 transition-colors hover:text-pulse-moss'
      ) do
        raw view_context.icon('x', class: 'w-4 h-4')
      end
    end

    def title_text_class
      @type.alert? ? 'text-rose-600' : 'text-pulse-forest'
    end

    def body_text_class
      @type.alert? ? 'text-rose-600' : 'text-pulse-forest'
    end

    def toast_container_classes
      @type.alert? ? 'border-rose-500/20 bg-rose-500/10' : 'border-pulse-forest/20 bg-pulse-forest/10'
    end

    def toast_icon_container
      div(class: "flex h-10 w-10 shrink-0 items-center justify-center rounded-2xl
                #{toast_icon_container_classes}") do
        toast_icon
      end
    end

    def toast_icon_container_classes
      @type.alert? ? 'bg-rose-500/20' : 'bg-pulse-forest/20'
    end

    def toast_icon
      @type.alert? ? '⚠️' : '🌿'
    end

    def toast_title
      I18n.t(@type.alert? ? 'flash.toast.alert_title' : 'flash.toast.success_title').upcase
    end
  end
end
