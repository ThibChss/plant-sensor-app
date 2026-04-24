require 'vips'
module Admin
  class SensorsController < Admin::BaseController
    before_action :set_sensor, only: %i[destroy qr_sticker qr_sticker_preview destroy_confirmation]

    def index
      @sensors = Sensor.includes(:user, :plant).order(created_at: :desc)
    end

    def new
      @sensor = Sensor.new
    end

    def create
      @sensor = Sensor.create!

      redirect_to admin_sensors_path, notice: t('.created', uid: @sensor.uid)
    rescue ActiveRecord::RecordInvalid => e
      redirect_to new_admin_sensor_path, alert: e.record.errors.full_messages.to_sentence
    end

    def qr_sticker
      svg = render_to_string(Components::SensorSticker.new(sensor: @sensor), layout: false)
      png = Vips::Image.svgload_buffer(svg.b, scale: 4).write_to_buffer('.png')

      send_data png,
                filename: "sticker-#{@sensor.uid}.png",
                type: 'image/png',
                disposition: 'attachment'
    end

    def qr_sticker_preview
      render_partial(
        partial: 'qr_sticker_modal_content',
        dialog_id: 'admin-shared-qr-sticker'
      )
    end

    def destroy_confirmation
      render_partial(
        partial: 'destroy_sensor_modal_content',
        dialog_id: 'admin-shared-destroy-sensor'
      )
    end

    def destroy
      @sensor.destroy!

      redirect_to admin_sensors_path, notice: t('.notice', uid: @sensor.uid)
    rescue ActiveRecord::RecordNotFound
      redirect_to admin_sensors_path, alert: t('.not_found')
    rescue ActiveRecord::RecordNotDestroyed
      redirect_to admin_sensors_path, alert: t('.alert_failed')
    end

    private

    def set_sensor
      @sensor = Sensor.includes(:user).find(params[:id])
    end

    def render_partial(partial:, dialog_id:)
      render partial:,
             layout: false,
             locals: {
               sensor: @sensor,
               dialog_id:
             }
    end
  end
end
