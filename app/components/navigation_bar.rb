# frozen_string_literal: true

module Components
  class NavigationBar < Components::Base
    def view_template
      nav(
        class: 'pointer-events-auto flex h-20 w-full items-center justify-around rounded-t-[2.5rem] border border-white/40 bg-white/40 px-2 shadow-2xl shadow-pulse-forest/10 backdrop-blur-lg'
      ) do
        button(
          class: 'group flex h-14 w-14 items-center justify-center rounded-full text-pulse-moss transition-all hover:bg-pulse-sage/10 active:scale-90'
        ) { nav_icon('chart-column', 'w-6 h-6') }

        nav_tab_link(href: root_path, active: home_active?) { nav_icon('house', 'w-6 h-6') }

        button(
          class: 'group relative -mt-10 flex h-16 w-16 items-center justify-center rounded-full bg-pulse-forest text-white shadow-xl shadow-pulse-forest/30 transition-all hover:scale-105 active:scale-95'
        ) { nav_icon('plus', 'w-8 h-8 stroke-[3]') }

        button(
          class: 'group flex h-14 w-14 items-center justify-center rounded-full text-pulse-moss transition-all hover:bg-pulse-sage/10 active:scale-90'
        ) { nav_icon('bell', 'w-6 h-6') }

        nav_tab_link(href: profile_path, active: profile_active?) { nav_icon('user', 'w-6 h-6') }
      end
    end

    private

    def home_active?
      view_context.current_page?(root_path)
    end

    def profile_active?
      view_context.current_page?(profile_path)
    end

    def nav_tab_link(href:, active:)
      inactive = 'group flex h-14 w-14 items-center justify-center rounded-full text-pulse-moss transition-all hover:bg-pulse-sage/10 active:scale-90'
      active_cls = 'relative flex h-14 w-14 items-center justify-center rounded-3xl bg-pulse-sage/10 text-pulse-forest transition-all active:scale-90'

      link_attrs = { href: href, class: active ? active_cls : inactive }
      link_attrs[:aria] = { current: 'page' } if active

      a(**link_attrs) do
        yield
        div(class: 'absolute -bottom-1 h-1 w-5 rounded-full bg-pulse-forest') if active
      end
    end

    def nav_icon(name, icon_class)
      raw view_context.icon(name, class: icon_class)
    end
  end
end
