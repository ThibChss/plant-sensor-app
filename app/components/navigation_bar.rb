# frozen_string_literal: true

module Components
  class NavigationBar < Components::Base
    def view_template
      div(class: "relative z-30 shrink-0 pb-[env(safe-area-inset-bottom)]") do
        render_nav
        render_analytics_modal_container
      end
    end

    private

    def render_nav
      nav(class: nav_classes) do
        render_chart_button
        render_tab(href: sensors_path, icon: "house", active: home_active?)
        render_add_button
        render_notifications_button
        render_tab(href: profile_path, icon: "user", active: profile_active?)
      end
    end

    def render_tab(href:, icon:, active:)
      a(**tab_attrs(href:, active:)) do
        nav_icon(icon, "w-6 h-6")
        active_indicator if active
      end
    end

    def render_chart_button
      button(**chart_button_attrs) do
        nav_icon("chart-column", "w-6 h-6")
        active_indicator if analytics_active?
      end
    end

    def render_add_button
      a(href: new_sensors_setup_path, class: fab_classes) do
        nav_icon("plus", "w-8 h-8 stroke-[3]")
      end
    end

    def render_notifications_button
      button(class: nav_item_classes(false)) do
        nav_icon("bell", "w-6 h-6")
      end
    end

    def render_analytics_modal_container
      div(class: "pointer-events-none fixed inset-0 z-[60] max-h-none overflow-x-hidden [&_dialog]:pointer-events-auto [&_el-dialog]:pointer-events-auto") do
        raw analytics_modal_markup
      end
    end

    def active_indicator
      div(class: "absolute -bottom-1 h-1 w-5 rounded-full bg-pulse-forest")
    end

    # Attrs builders

    def tab_attrs(href:, active:)
      attrs = {
        href:,
        class: nav_item_classes(active)
      }
      attrs[:aria] = { current: "page" } if active

      attrs
    end

    def chart_button_attrs
      attrs = {
        type: :button,
        class: nav_item_classes(analytics_active?),
        command: "show-modal",
        commandfor: "sensor-analytics-dialog"
      }
      attrs[:aria] = { current: "page" } if analytics_active?

      attrs
    end

    # Data

    def analytics_modal_markup
      ApplicationController.render(
        partial: "shared/sensor_analytics_modal",
        locals: {
          sensors: analytics_sensors,
          selected_sensor_id: selected_analytics_sensor_id
        }
      )
    end

    def analytics_sensors
      Current.user&.sensors&.includes(:plant)&.order(:nickname) || []
    end

    def selected_analytics_sensor_id
      view_context.params[:sensor_id] if analytics_active?
    end

    # Active state helpers

    def analytics_active?
      view_context.controller_path == "sensors/sensor_readings" &&
        view_context.action_name == "index"
    end

    def home_active?
      view_context.current_page?(sensors_path)
    end

    def profile_active?
      view_context.current_page?(profile_path)
    end

    # CSS helpers

    def nav_classes
      "pointer-events-auto flex h-20 w-full items-center justify-around rounded-t-[2.5rem] border border-white/40 bg-white/40 px-2 shadow-2xl shadow-pulse-forest/10 backdrop-blur-lg"
    end

    def fab_classes
      "group relative z-10 -mt-10 flex h-16 w-16 items-center justify-center rounded-full bg-pulse-forest text-white shadow-xl shadow-pulse-forest/30 transition-all hover:scale-105 active:scale-95"
    end

    def nav_item_classes(active, base: "flex h-14 w-14 items-center justify-center rounded-full transition-all active:scale-90")
      if active
        "relative #{base} rounded-3xl bg-pulse-sage/10 text-pulse-forest"
      else
        "#{base} group text-pulse-moss hover:bg-pulse-sage/10"
      end
    end

    def nav_icon(name, icon_class)
      raw view_context.icon(name, class: icon_class)
    end
  end
end
