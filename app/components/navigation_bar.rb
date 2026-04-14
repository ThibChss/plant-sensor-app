# frozen_string_literal: true

module Components
  class NavigationBar < Components::Base
    def view_template
      # z-30: stay above scrollable panes that use z-10 (e.g. sensor readings over the hero) so the
      # raised FAB (-mt-10) is not covered by chart cards / canvas compositing while scrolling.
      div(class: 'relative z-30 shrink-0 pb-[env(safe-area-inset-bottom)]') do
        nav(
          class: 'pointer-events-auto flex h-20 w-full items-center justify-around rounded-t-[2.5rem] border border-white/40 bg-white/40 px-2 shadow-2xl shadow-pulse-forest/10 backdrop-blur-lg'
        ) do
          chart_nav_control

          nav_tab_link(href: sensors_path, active: home_active?) { nav_icon('house', 'w-6 h-6') }

          a(
            href: new_sensors_setup_path,
            class: 'group relative z-10 -mt-10 flex h-16 w-16 items-center justify-center rounded-full bg-pulse-forest text-white shadow-xl shadow-pulse-forest/30 transition-all hover:scale-105 active:scale-95'
          ) { nav_icon('plus', 'w-8 h-8 stroke-[3]') }

          button(
            class: 'group flex h-14 w-14 items-center justify-center rounded-full text-pulse-moss transition-all hover:bg-pulse-sage/10 active:scale-90'
          ) { nav_icon('bell', 'w-6 h-6') }

          nav_tab_link(href: profile_path, active: profile_active?) { nav_icon('user', 'w-6 h-6') }
        end

        div(class: 'pointer-events-none fixed inset-0 z-[60] max-h-none overflow-x-hidden [&_dialog]:pointer-events-auto [&_el-dialog]:pointer-events-auto') do
          raw analytics_modal_markup
        end
      end
    end

    private

    def chart_nav_control
      attrs = {
        type: :button,
        class: nav_item_classes(analytics_active?),
        command: 'show-modal',
        commandfor: 'sensor-analytics-dialog'
      }
      attrs[:aria] = { current: 'page' } if analytics_active?

      button(**attrs) do
        nav_icon('chart-column', 'w-6 h-6')
        div(class: 'absolute -bottom-1 h-1 w-5 rounded-full bg-pulse-forest') if analytics_active?
      end
    end

    def analytics_modal_markup
      ApplicationController.render(
        partial: 'shared/sensor_analytics_modal',
        locals: {
          sensors: analytics_sensors,
          selected_sensor_id: selected_analytics_sensor_id
        }
      )
    end

    def analytics_sensors
      user = Current.user
      return [] unless user

      user.sensors.includes(:plant).order(:nickname)
    end

    def selected_analytics_sensor_id
      view_context.params[:sensor_id] if analytics_active?
    end

    def analytics_active?
      view_context.controller_path == 'sensors/sensor_readings' && view_context.action_name == 'index'
    end

    def home_active?
      view_context.current_page?(sensors_path)
    end

    def profile_active?
      view_context.current_page?(profile_path)
    end

    def nav_item_classes(active)
      if active
        'relative flex h-14 w-14 items-center justify-center rounded-3xl bg-pulse-sage/10 text-pulse-forest transition-all active:scale-90'
      else
        'group flex h-14 w-14 items-center justify-center rounded-full text-pulse-moss transition-all hover:bg-pulse-sage/10 active:scale-90'
      end
    end

    def nav_tab_link(href:, active:)
      link_attrs = { href: href, class: nav_item_classes(active) }
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
