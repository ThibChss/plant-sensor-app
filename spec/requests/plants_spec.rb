require 'rails_helper'

RSpec.describe 'Plants', type: :request do
  with_user_signed_in :persisted_forced

  let(:plant_json_path) { Rails.root.join('spec/fixtures/files/plants_for_finder.json') }

  before do
    stub_const('Plants::Finder::JSON_FILE_PATH', plant_json_path)
    allow(Plants::Finder).to receive(:call).and_call_original
  end

  describe 'GET /plants/search' do
    shared_examples 'returns JSON from Plants::Finder' do
      it 'returns JSON from Plants::Finder' do
        get search_plants_path, params: { query: }

        expect(response).to have_http_status(:ok)
        expect(JSON.parse(response.body)).to eq(search_results)
      end
    end

    let(:query) { 'oak' }

    context 'when not signed in' do
      with_user_signed_out

      it 'redirects to the sign-in page' do
        get search_plants_path, params: { query: }

        expect(response).to redirect_to(new_session_path)
      end
    end

    context 'when signed in' do
      let(:query) { 'serpent' }
      let(:search_results) do
        [
          {
            name: "Snake Plant",
            scientific_name: "Sansevieria trifasciata",
            translated_name: {
              en: ["Mother-in-law tongue"],
              fr: ["Plante serpent"]
            }
          }.deep_stringify_keys
        ]
      end

      include_examples 'returns JSON from Plants::Finder'

      context 'when the finder returns no results' do
        let(:query) { 'xyz' }
        let(:search_results) { [] }

        include_examples 'returns JSON from Plants::Finder'
      end
    end
  end

  describe 'POST /plants/prepare' do
    let(:plant_payload) do
      {
        trefle_id: 'tref-99',
        name: 'Monstera',
        scientific_name: 'Monstera deliciosa',
        image_url: 'https://example.com/m.jpg'
      }
    end

    let(:enrich_result) do
      {
        ok: true,
        plant_id: nil,
        min_soil_moisture: {
          indoor: 40,
          outdoor: 35
        }
      }
    end

    def prepare_plant
      post prepare_plants_path,
           params: { plant: plant_payload },
           as: :json
    end

    context 'when not signed in' do
      with_user_signed_out

      it 'redirects to the sign-in page' do
        prepare_plant

        expect(response).to redirect_to(new_session_path)
      end
    end

    context 'when signed in' do
      before do
        allow(Plants::EnrichGrowthData).to receive(:call) do |plant_id|
          enrich_result.merge(plant_id:)
        end
      end

      it 'creates a plant, enriches it, and returns JSON' do
        expect do
          prepare_plant
        end.to change(Plant, :count).by(1)

        expect(response).to have_http_status(:ok)

        expect(response.parsed_body['ok']).to be(true)
        expect(response.parsed_body['plant_id']).to eq(Plant.last.id)
        expect(response.parsed_body['min_soil_moisture']).to eq({ 'indoor' => 40, 'outdoor' => 35 })

        expect(Plants::EnrichGrowthData).to have_received(:call).with(Plant.find_by!(trefle_id: 'tref-99').id)
      end

      context 'when the plant already exists for that trefle_id' do
        let!(:plant) do
          create(:plant, trefle_id: 'tref-99', name: 'Old', scientific_name: 'Old.sci', image_url: 'https://example.com/old.jpg')
        end

        it 'does not create another plant and still enriches' do
          expect do
            prepare_plant
          end.not_to change(Plant, :count)

          expect(response).to have_http_status(:ok)

          expect(response.parsed_body['ok']).to be(true)
          expect(response.parsed_body['plant_id']).to eq(plant.id.to_s)

          expect(Plants::EnrichGrowthData).to have_received(:call).with(plant.id)
        end
      end

      context 'when the new plant is invalid' do
        let(:plant_payload) do
          {
            trefle_id: 'tref-invalid',
            name: '',
            scientific_name: 'X',
            image_url: 'https://example.com/x.jpg'
          }
        end

        it 'returns unprocessable entity with errors' do
          expect do
            prepare_plant
          end.not_to change(Plant, :count)

          expect(response).to have_http_status(:unprocessable_content)

          expect(response.parsed_body['ok']).to be(false)
          expect(response.parsed_body['message']).to be_present
        end
      end
    end
  end
end
