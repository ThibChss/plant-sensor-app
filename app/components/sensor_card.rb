# frozen_string_literal: true

module Components
  class SensorCard < Components::Base
    def initialize(sensor:)
      @sensor = sensor
      @plant = sensor.plant
    end

    def view_template
      a(
        href: sensor_path(@sensor),
        id: @sensor.dom_id,
        class: "#{container_classes} block w-full overflow-hidden rounded-[2.5rem] border transition-all duration-700 group [&:not(:last-child)]:mb-6 active:scale-[0.98]"
      ) do
        image_section
        body_section
      end
    end

    private

    def container_classes
      if @sensor.thirsty?
        'bg-rose-50/80 border-rose-200/60 shadow-sm'
      else
        'bg-white border-white/50 shadow-sm'
      end
    end

    def image_section
      div(class: 'relative h-40 w-full overflow-hidden bg-pulse-mist') do
        img(
          src: @plant.image_url,
          alt: view_context.t('sensors.sensor_card.plant_image_alt', name: @sensor.nickname),
          class: "h-full w-full object-cover transition-transform duration-1000 group-hover:scale-110 #{'opacity-50 grayscale-[20%]' unless @sensor.moisture_level_present?}"
        )

        div(class: 'absolute inset-0 bg-gradient-to-t from-black/50 via-transparent to-transparent')

        div(class: 'absolute top-4 left-4 flex gap-2') do
          conditional_badges

          span(class: 'rounded-full bg-white/20 px-3 py-1.5 text-[10px] font-bold uppercase tracking-widest text-white backdrop-blur-md border border-white/20') do
            plain view_context.t("sensor.location.#{@sensor.location}")
          end
        end

        div(class: 'absolute bottom-4 left-6 right-6') do
          h4(class: 'text-2xl font-black text-white leading-tight drop-shadow-md font-alegreya') do
            plain @sensor.nickname
          end
        end
      end
    end

    def conditional_badges
      if @sensor.thirsty?
        span(
          class: 'inline-flex items-center gap-1 rounded-full bg-rose-500/40 px-3 py-1.5 text-[10px] font-black uppercase tracking-widest text-white shadow-lg shadow-rose-500/5 backdrop-blur-md border border-white/20'
        ) do
          span(class: 'animate-pulse', aria: { hidden: true }) { plain "\u{1f4a7}" }
          plain ' '
          plain view_context.t('sensors.sensor_card.thirsty_badge')
        end
      elsif !@sensor.moisture_level_present?
        span(
          class: 'inline-flex items-center gap-1 rounded-full bg-pulse-forest/20 px-3 py-1.5 text-[10px] font-black uppercase tracking-widest text-white backdrop-blur-md border border-white/10'
        ) { plain view_context.t('sensors.sensor_card.offline_badge') }
      end
    end

    def body_section
      div(class: 'p-6 text-center') do
        monitoring_row
        progress_block
        botanical_block
        sync_footer
      end
    end

    def monitoring_row
      div(class: 'flex items-start justify-between mb-5 px-1') do
        div(class: 'flex flex-col items-start') do
          p(class: 'text-[9px] font-bold text-pulse-moss uppercase tracking-[0.2em] mb-1.5 opacity-60 font-palanquin') do
            plain view_context.t(
              'sensors.sensor_card.moisture_environment',
              environment: view_context.t("sensor.environment.#{@sensor.environment}")
            )
          end

          div(class: 'flex items-baseline gap-0.5') do
            moisture_level_block_content
          end
        end

        display_light_block if @plant.light.present?
      end
    end

    def moisture_level_block_content
      if @sensor.moisture_level_present?
        span(
          class: "text-3xl font-black #{@sensor.thirsty? ? 'text-rose-500/90' : 'text-pulse-forest'} font-alegreya leading-none"
        ) do
          plain @sensor.moisture_level_percent.to_s
        end

        span(
          class: "text-sm font-bold #{@sensor.thirsty? ? 'text-rose-500/60' : 'text-pulse-forest/60'} font-alegreya"
        ) do
          plain '%'
        end
      else
        span(class: 'text-lg font-bold text-pulse-moss/30 font-alegreya italic tracking-tight') do
          plain view_context.t('sensors.sensor_card.calculating')
        end
      end
    end

    def display_light_block
      div(class: 'flex flex-col items-end') do
        p(class: 'text-[9px] font-bold text-pulse-moss uppercase tracking-[0.2em] mb-1.5 opacity-60 font-palanquin') do
          plain view_context.t('sensors.show.light_label')
        end

        div(class: 'flex items-baseline gap-1.5') do
          span(class: 'text-lg font-black text-pulse-forest font-alegreya leading-none') do
            plain "#{@plant.light}/10"
          end

          div(class: 'translate-y-[1px]') { raw view_context.icon('sun', class: 'w-3.5 h-3.5 text-pulse-sage') }
        end
      end
    end

    def progress_block
      div(class: 'relative mb-6') do
        svg(
          class: 'h-1.5 w-full rounded-full',
          viewBox: '0 0 100 2',
          preserveAspectRatio: 'none',
          aria: { hidden: true }
        ) { progress_bar_svg(it) }

        critical_threshold_block
      end
    end

    def progress_bar_svg(svg_element)
      svg_element.rect(width: '100', height: '2', rx: '1', class: @sensor.thirsty? ? 'fill-rose-900/10' : 'fill-pulse-forest/10')

      return unless @sensor.moisture_level_present?

      svg_element.rect(
        width: @sensor.moisture_level_percent.to_s,
        height: '2',
        rx: '1',
        class: "#{@sensor.thirsty? ? 'fill-rose-500/80' : 'fill-pulse-forest'} transition-all duration-1000"
      )
    end

    def critical_threshold_block
      if @sensor.thirsty?
        p(class: 'text-[9px] font-bold text-rose-500/70 mt-2 uppercase tracking-tighter text-left px-1') do
          plain view_context.t('sensors.sensor_card.critical_threshold', value: @sensor.moisture_threshold)
        end
      elsif !@sensor.moisture_level_present?
        p(class: 'text-[9px] font-bold text-pulse-moss/30 mt-2 uppercase tracking-widest text-center px-1') do
          plain view_context.t('sensors.sensor_card.plug_bridge')
        end
      end
    end

    def botanical_block
      div(class: 'pt-4 border-t border-pulse-mist/50 flex flex-col gap-1') do
        p(class: 'text-xs font-bold text-pulse-forest italic font-merriweather opacity-80 leading-snug px-4') do
          plain @plant.display_name
        end
        p(class: 'text-[9px] text-pulse-moss/40 font-medium uppercase tracking-[0.15em] font-palanquin') do
          plain @plant.scientific_name
        end
      end
    end

    def sync_footer
      div(class: 'mt-4 flex justify-center') do
        span(
          class: 'inline-flex items-center px-4 py-1.5 bg-pulse-mist/30 rounded-full text-[9px] font-bold text-pulse-moss/40 uppercase tracking-tighter font-palanquin'
        ) do
          if @sensor.last_seen_at.present?
            plain view_context.t('sensors.sensor_card.last_sync', time: view_context.time_ago_in_words(@sensor.last_seen_at))
          else
            raw view_context.icon('signal', class: 'w-3 h-3 mr-1.5 opacity-40')
            plain ' '
            plain view_context.t('sensors.sensor_card.awaiting_sync')
          end
        end
      end
    end
  end
end
