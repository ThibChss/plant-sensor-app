module Components
  class SensorQrCode < Components::Base
    def initialize(sensor:, width: nil, height: nil, x: 0, y: 0)
      @sensor = sensor
      @modules = sensor.qr_code.modules
      @width = width
      @height = height
      @x = x
      @y = y
    end

    def view_template
      svg(
        viewBox: "0 0 #{module_count} #{module_count}",
        xmlns: "http://www.w3.org/2000/svg",
        width: @width || "100%",
        height: @height || "100%",
        x: @x,
        y: @y
      ) do |s|
        @modules.each_with_index do |row, row_index|
          row.each_with_index do |filled, col_index|
            next unless filled

            # Utilisation impérative du builder 's'
            s.circle(cx: col_index + 0.5, cy: row_index + 0.5, r: 0.42, fill: "#346739")
          end
        end
      end
    end

    private

    def module_count
      @module_count ||= @modules.size
    end
  end
end
