# frozen_string_literal: true

module Components
  class SensorQrCode < Components::Base
    DOT_COLOR = '#346739'
    DOT_RADIUS = 0.38
    FINDER_RADIUS = 0.45

    private_constant :DOT_COLOR, :DOT_RADIUS, :FINDER_RADIUS

    def initialize(sensor:)
      @sensor = sensor
      @qrcode = sensor.qr_code
      @modules = @qrcode.modules
    end

    def view_template
      artistic_qr_code
    end

    private

    def artistic_qr_code
      svg(
        viewBox: "0 0 #{module_count} #{module_count}",
        xmlns: 'http://www.w3.org/2000/svg',
        class: 'h-full w-full drop-shadow-sm'
      ) do |svg|
        @modules.each_with_index do |row, row_index|
          row.each_with_index do |filled, col_index|
            next unless filled

            generate_circle(svg, col_index, row_index)
          end
        end
      end
    end

    def generate_circle(svg, col_index, row_index)
      if finder_cell?(col_index, row_index)
        svg.circle(cx: col_index + 0.5, cy: row_index + 0.5, r: FINDER_RADIUS, fill: DOT_COLOR)
      else
        svg.circle(cx: col_index + 0.5, cy: row_index + 0.5, r: DOT_RADIUS, fill: DOT_COLOR, opacity: '0.9')
      end
    end

    def finder_cell?(col_index, row_index)
      (col_index < 7 && row_index < 7) ||
        (col_index < 7 && row_index >= module_count - 7) ||
        (col_index >= module_count - 7 && row_index < 7)
    end

    def module_count
      @module_count ||= @qrcode.modules.size
    end
  end
end
