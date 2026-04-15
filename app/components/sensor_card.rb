# frozen_string_literal: true

module Components
  class SensorCard < Components::Base
    def initialize(sensor:)
      @sensor = sensor
      @plant = sensor.plant
    end

    def view_template
      a(href: sensor_path(@sensor), id: @sensor.dom_id, class: card_classes) do
        cache [@sensor, @plant, I18n.locale], expires_in: 1.hour do
          image_section
          body_section
        end

        sync_footer
      end
    end

    private

    # — Sections —

    def image_section
      div(class: "relative h-40 w-full overflow-hidden bg-pulse-mist") do
        render_plant_image
        render_image_gradient
        render_image_badges
        render_image_title
      end
    end

    def body_section
      div(class: "p-6 text-center") do
        monitoring_row
        progress_block
        botanical_block
      end
    end

    # — Image section —

    def render_plant_image
      img(
        src: @plant.image_url,
        alt: t("sensors.sensor_card.plant_image_alt", name: @sensor.nickname),
        class: plant_image_classes
      )
    end

    def render_image_gradient
      div(class: "absolute inset-0 bg-gradient-to-t from-black/50 via-transparent to-transparent")
    end

    def render_image_badges
      div(class: "absolute top-4 left-4 flex gap-2") do
        render_status_badge
        render_location_badge
      end
    end

    def render_image_title
      div(class: "absolute bottom-4 left-6 right-6") do
        h4(class: "text-2xl font-black text-white leading-tight drop-shadow-md font-alegreya") do
          plain @sensor.nickname
        end
      end
    end

    def render_status_badge
      if @sensor.thirsty?
        span(class: thirsty_badge_classes) do
          span(class: "animate-pulse", aria: { hidden: true }) { plain "\u{1f4a7}" }

          plain " #{t('sensors.sensor_card.thirsty_badge')}"
        end
      elsif !@sensor.moisture_level_present?
        span(class: offline_badge_classes) { plain t("sensors.sensor_card.offline_badge") }
      end
    end

    def render_location_badge
      span(class: location_badge_classes) do
        plain t("sensor.location.#{@sensor.location}")
      end
    end

    # — Body section —

    def monitoring_row
      div(class: "flex items-start justify-between mb-5 px-1") do
        render_moisture_column
        render_light_column if @plant.light.present?
      end
    end

    def render_moisture_column
      div(class: "flex flex-col items-start") do
        p(class: section_label_classes) do
          plain t("sensors.sensor_card.moisture_environment",
                  environment: t("sensor.environment.#{@sensor.environment}"))
        end

        div(class: "flex items-baseline gap-0.5") { render_moisture_value }
      end
    end

    def render_moisture_value
      if @sensor.moisture_level_present?
        span(class: "text-3xl font-black #{moisture_color} font-alegreya leading-none") do
          plain @sensor.moisture_level_percent.to_s
        end

        span(class: "text-sm font-bold #{moisture_color}/60 font-alegreya") { plain "%" }
      else
        span(class: "text-lg font-bold text-pulse-moss/30 font-alegreya italic tracking-tight") do
          plain t("sensors.sensor_card.calculating")
        end
      end
    end

    def render_light_column
      div(class: "flex flex-col items-end") do
        p(class: section_label_classes) { plain t("sensors.show.light_label") }

        div(class: "flex items-baseline gap-1.5") do
          span(class: "text-lg font-black text-pulse-forest font-alegreya leading-none") do
            plain "#{@plant.light}/10"
          end

          div(class: "translate-y-[1px]") { raw icon("sun", class: "w-3.5 h-3.5 text-pulse-sage") }
        end
      end
    end

    def progress_block
      div(class: "relative mb-6") do
        render_progress_bar
        render_threshold_message
      end
    end

    def render_progress_bar
      svg(class: "h-1.5 w-full rounded-full", viewBox: "0 0 100 2",
          preserveAspectRatio: "none", aria: { hidden: true }) do |element|
        element.rect(width: "100", height: "2", rx: "1", class: track_fill)

        if @sensor.moisture_level_present?
          element.rect(width: @sensor.moisture_level_percent.to_s, height: "2", rx: "1",
                       class: "#{bar_fill} transition-all duration-1000")
        end
      end
    end

    def render_threshold_message
      if @sensor.thirsty?
        p(class: "text-[9px] font-bold text-rose-500/70 mt-2 uppercase tracking-tighter text-left px-1") do
          plain t("sensors.sensor_card.critical_threshold", value: @sensor.moisture_threshold)
        end
      elsif !@sensor.moisture_level_present?
        p(class: "text-[9px] font-bold text-pulse-moss/30 mt-2 uppercase tracking-widest text-center px-1") do
          plain t("sensors.sensor_card.plug_bridge")
        end
      end
    end

    def botanical_block
      div(class: "pt-4 border-t border-pulse-mist/50 flex flex-col gap-1") do
        p(class: "text-xs font-bold text-pulse-forest italic font-merriweather opacity-80 leading-snug px-4") do
          plain @plant.display_name
        end

        p(class: "text-[9px] text-pulse-moss/40 font-medium uppercase tracking-[0.15em] font-palanquin") do
          plain @plant.scientific_name
        end
      end
    end

    def sync_footer
      div(class: "mb-4 flex justify-center") do
        if @sensor.last_seen_at.present?
          span(
            class: sync_badge_classes,
            data: {
              controller: "time-ago",
              time_ago_time_value: @sensor.last_seen_at.iso8601
            }
          ) do
            plain t("sensors.time_ago.less_than_minute")
          end
        else
          span(class: sync_badge_classes) do
            raw icon("signal", class: "w-3 h-3 mr-1.5 opacity-40")
            plain " #{t('sensors.sensor_card.awaiting_sync')}"
          end
        end
      end
    end

    # — CSS helpers —

    def card_classes
      state = @sensor.thirsty? ? "bg-rose-50/80 border-rose-200/60" : "bg-white border-white/50"

      "#{state} block w-full overflow-hidden rounded-[2.5rem] border shadow-sm transition-all duration-700 group [&:not(:last-child)]:mb-6 active:scale-[0.98]"
    end

    def plant_image_classes
      base = "h-full w-full object-cover transition-transform duration-1000 group-hover:scale-110"

      @sensor.moisture_level_present? ? base : "#{base} opacity-50 grayscale-[20%]"
    end

    def moisture_color
      @sensor.thirsty? ? "text-rose-500/90" : "text-pulse-forest"
    end

    def track_fill
      @sensor.thirsty? ? "fill-rose-900/10" : "fill-pulse-forest/10"
    end

    def bar_fill
      @sensor.thirsty? ? "fill-rose-500/80" : "fill-pulse-forest"
    end

    def section_label_classes
      "text-[9px] font-bold text-pulse-moss uppercase tracking-[0.2em] mb-1.5 opacity-60 font-palanquin"
    end

    def thirsty_badge_classes
      "inline-flex items-center gap-1 rounded-full bg-rose-500/40 px-3 py-1.5 text-[10px] font-black uppercase tracking-widest text-white shadow-lg shadow-rose-500/5 backdrop-blur-md border border-white/20"
    end

    def offline_badge_classes
      "inline-flex items-center gap-1 rounded-full bg-pulse-forest/20 px-3 py-1.5 text-[10px] font-black uppercase tracking-widest text-white backdrop-blur-md border border-white/10"
    end

    def location_badge_classes
      "rounded-full bg-white/20 px-3 py-1.5 text-[10px] font-bold uppercase tracking-widest text-white backdrop-blur-md border border-white/20"
    end

    def sync_badge_classes
      "inline-flex items-center px-4 py-1.5 bg-pulse-mist/30 rounded-full text-[9px] font-bold text-pulse-moss/40 uppercase tracking-tighter font-palanquin"
    end
  end
end
