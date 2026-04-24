module Components
  class SensorSticker < Components::Base
    STICKER_WIDTH  = 400
    STICKER_HEIGHT = 120
    QR_SIZE        = 96
    BRAND_COLOR    = '#346739'

    def initialize(sensor:)
      @sensor = sensor
    end

    def view_template
      svg(
        viewBox: "0 0 #{STICKER_WIDTH} #{STICKER_HEIGHT}",
        xmlns: 'http://www.w3.org/2000/svg',
        width: "100%",
        height: "auto"
      ) do |s|
        render_background(s)
        render_text(s)
        render_qr_code
      end
    end

    private

    def render_background(s)
      s.rect(width: STICKER_WIDTH, height: STICKER_HEIGHT, fill: 'white')
      s.rect(width: STICKER_WIDTH, height: 8, fill: BRAND_COLOR)
      s.rect(y: STICKER_HEIGHT - 8, width: STICKER_WIDTH, height: 8, fill: BRAND_COLOR)
    end

    def render_qr_code
      x_offset = STICKER_WIDTH - QR_SIZE - 15
      y_offset = (STICKER_HEIGHT - QR_SIZE) / 2

      render Components::SensorQrCode.new(
        sensor: @sensor,
        width: QR_SIZE,
        height: QR_SIZE,
        x: x_offset,
        y: y_offset
      )
    end

    def render_text(s)
      text_x = 20
      s.text(x: text_x, y: 48, 'font-family': 'monospace', 'font-size': 14, 'font-weight': '900', fill: BRAND_COLOR) { @sensor.uid }
      s.text(x: text_x, y: 72, 'font-family': 'sans-serif', 'font-size': 10, 'font-weight': '600', fill: '#999') do
        t('admin.sensors.qr_sticker.sticker_pairing_svg_label')
      end
      s.text(x: text_x, y: 102, 'font-family': 'monospace', 'font-size': 32, 'font-weight': 'bold', fill: '#111') { @sensor.pairing_code }
    end
  end
end
