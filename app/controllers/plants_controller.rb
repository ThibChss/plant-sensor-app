class PlantsController < ApplicationController
  rate_limit to: 120, within: 1.minute, only: :search, name: 'plants-search',
             by: -> { rate_limit_identity }

  rate_limit to: 20, within: 10.minutes, only: :prepare, name: 'plants-prepare',
             by: -> { rate_limit_identity }

  def search
    @plants = Plants::Finder.call(query: search_params[:query])

    render json: @plants
  end

  def prepare
    @plant = Plant.find_or_initialize_by(trefle_id: prepare_params[:trefle_id].to_s.strip)

    if @plant.new_record?
      @plant.assign_attributes(
        prepare_params.except(:trefle_id)
      )

      @plant.save!
    end

    render json: enrich_growth_result
  rescue ActiveRecord::RecordInvalid => e
    render json: { ok: false, message: e.record.errors.full_messages.to_sentence },
           status: :unprocessable_content
  end

  private

  def prepare_params
    params.require(:plant).permit(
      :trefle_id, :name, :scientific_name, :image_url, translated_name: { en: [], fr: [] }
    )
  end

  def enrich_growth_result
    @enrich_growth_result ||= Plants::GrowthDataEnricher.call(@plant.id)
  end

  def search_params
    params.permit(:query)
  end

  def rate_limit_identity
    Current.user&.id || request.remote_ip
  end
end
