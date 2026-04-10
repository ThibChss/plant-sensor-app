require 'rails_helper'

RSpec.describe Plants::EnrichGrowthData do
  describe '#call' do
    let_it_be(:plant, refind: true) { create(:plant) }

    let(:expected_result) do
      {
        ok: true,
        plant_id: plant.id,
        min_soil_moisture: plant.min_soil_moisture
      }
    end

    let(:fetched) do
      attributes_for(:plant)[:growth_data].merge(
        'minimum_temperature' => -5.0,
        'maximum_temperature' => 35.0,
        'soil_humidity' => 6
      )
    end

    subject(:service) { described_class.call(plant.id) }

    context 'when growth profile was already enriched' do
      before do
        allow(Plants::GrowthDataFetcher).to receive(:call)

        plant.update_column(:growth_data, {
                              'light' => nil,
                              Plant::GROWTH_PROFILE_ENRICHED_KEY => true
                            })
      end

      it 'does not call the fetcher and returns ok' do
        expect(service).to eq(expected_result)
        expect(Plants::GrowthDataFetcher).not_to have_received(:call)
      end
    end

    context 'when growth data must be fetched' do
      before do
        allow(Plants::GrowthDataFetcher).to receive(:call).with(plant).and_return(fetched)

        plant.update_columns(
          growth_data: plant.growth_data.merge('light' => nil),
          min_temp: nil,
          max_temp: nil,
          ideal_humidity: nil
        )
      end

      it 'applies fetched data, saves, sets enriched marker, and returns ok' do
        expect(service).to eq(expected_result)

        plant.reload

        expect(plant.min_temp).to eq(-5.0)
        expect(plant.max_temp).to eq(35.0)
        expect(plant.ideal_humidity).to eq(6)
        expect(plant.light).to eq(10)
        expect(plant.growth_data[Plant::GROWTH_PROFILE_ENRICHED_KEY]).to be(true)
      end
    end

    context 'when the fetcher returns nil' do
      let(:plant) { create(:plant) }

      let(:expected_result) do
        {
          ok: false,
          message: I18n.t('plants.enrich_growth_data.fetch_failure')
        }
      end

      before do
        allow(Plants::GrowthDataFetcher).to receive(:call).and_return(nil)

        plant.update_columns(
          growth_data: plant.growth_data.merge('light' => nil),
          min_temp: nil,
          max_temp: nil,
          ideal_humidity: nil
        )
      end

      it 'returns a failure message' do
        expect(service).to eq(expected_result)
      end
    end

    context 'when the plant is not valid' do
      before do
        allow(Plants::GrowthDataFetcher).to receive(:call).and_return(fetched)

        plant.update_column(:name, nil)
      end

      it 'returns a failure message' do
        plant.reload.valid?

        expect(service[:ok]).to be(false)
        expect(service[:message]).to eq(plant.errors.full_messages.to_sentence)
      end
    end
  end
end
