require 'rails_helper'

RSpec.describe Plant, type: :model do
  describe 'validations' do
    describe 'presence' do
      subject { build(:plant) }

      it { should validate_presence_of(:name) }
      it { should validate_presence_of(:scientific_name) }
      it { should validate_presence_of(:trefle_id) }
      it { should validate_presence_of(:image_url) }
    end

    describe 'uniqueness' do
      subject { build(:plant) }

      it { should validate_uniqueness_of(:trefle_id) }
    end

    describe 'conditional presence of growth_data' do
      context 'when all accessor keys are present in growth_data' do
        subject { build(:plant) }

        it { should be_valid }
      end
    end

    describe 'month fields (bloom_months, fruit_months, growth_months)' do
      let(:valid_months) { Plant::MONTHS }
      let(:plant) { build(:plant) }

      context 'when bloom_months contains an invalid month name' do
        before { plant.bloom_months = ['not_a_real_month'] }

        it 'is invalid and adds an error on bloom_months' do
          expect(plant).not_to be_valid
          expect(plant.errors[:bloom_months]).to be_present
        end
      end

      context 'when fruit_months contains a value that is not a valid month' do
        before { plant.fruit_months = ['smarch'] }

        it 'is invalid and adds an error on fruit_months' do
          expect(plant).not_to be_valid
          expect(plant.errors[:fruit_months]).to be_present
        end
      end

      context 'when growth_months is not an array' do
        before { plant.growth_months = 'march' }

        it 'is invalid and adds an error on growth_months' do
          expect(plant).not_to be_valid
          expect(plant.errors[:growth_months]).to be_present
        end
      end

      context 'when all month arrays are empty' do
        before do
          plant.bloom_months = []
          plant.fruit_months = []
          plant.growth_months = []
        end

        it 'is valid (vacuous check)' do
          expect(plant).to be_valid
        end
      end

      context 'when month arrays only contain full month names' do
        before do
          plant.bloom_months = [valid_months.first]
          plant.fruit_months = [valid_months.last]
          plant.growth_months = valid_months.sample(2)
        end

        it 'is valid' do
          expect(plant).to be_valid
        end
      end
    end
  end

  describe 'growth_data store accessors' do
    let(:plant) { build(:plant) }

    it 'reads and writes nested keys on growth_data' do
      expect(plant.light).to eq(10)
      expect(plant.growth_data['light']).to eq(10)
    end
  end

  describe 'translated_name store accessors' do
    let(:fr_names) { %w[Chêne vert] }
    let(:en_names) { %w[Evergreen Oak] }
    let(:plant) { build(:plant, translated_name: { en: en_names, fr: fr_names }) }

    it 'reads and writes en/fr prefixes from translated_name json' do
      expect(plant.translated_name['en']).to eq(en_names)
      expect(plant.translated_name['fr']).to eq(fr_names)

      expect(plant.translated_name_en).to eq(en_names)
      expect(plant.translated_name_fr).to eq(fr_names)
    end
  end

  describe 'instance methods' do
    describe 'growth_data_complete?' do
      context 'when growth_data is not enriched' do
        let(:plant) { build(:plant) }

        it 'returns false' do
          expect(plant.growth_data_complete?).to be(false)
        end
      end

      context 'when growth_data is enriched' do
        let(:plant) { build(:plant, :enriched) }

        it 'returns true' do
          expect(plant.growth_data_complete?).to be(true)
        end
      end
    end

    describe 'display_name' do
      let(:default_scientific_name) { "Quercus rotundifolia" }

      let(:fr_names) { ["Chêne vert"] }
      let(:en_names) { ["Evergreen Oak"] }

      let(:translated_name) { { "fr" => fr_names, "en" => en_names } }

      let(:plant) { build(:plant, scientific_name: default_scientific_name, translated_name:) }

      before do
        allow(I18n).to receive(:locale).and_return(:fr)
      end

      context "when translated_name for the current locale exists and is non-empty" do
        it "returns the first translated name, titleized" do
          expect(plant.display_name).to eq("Chêne Vert")
        end
      end

      context "when translated_name for the current locale is empty or nil" do
        let(:translated_name) { { "fr" => [], "en" => nil } }

        it "falls back to the base name and titleizes it" do
          expect(plant.display_name).to eq("Quercus Rotundifolia")
        end
      end

      context "when translated_name for the current locale does not exist" do
        let(:translated_name) { { "fr" => nil, "en" => nil } }

        it "falls back to the base name and titleizes it" do
          expect(plant.display_name).to eq("Quercus Rotundifolia")
        end
      end

      context "when translated_name contains multiple names for locale" do
        let(:fr_names) { ["Chêne vert", "Chêne à feuillage persistant"] }

        it "uses only the first translated name" do
          expect(plant.display_name).to eq("Chêne Vert")
        end
      end

      context "when a translated name is present but is an empty string" do
        let(:translated_name) { { "fr" => [""] } }

        it "falls back to the base name and titleizes it" do
          expect(plant.display_name).to eq("Quercus Rotundifolia")
        end
      end

      context "when the translated name exists for other locale but not current" do
        let(:translated_name) { { "en" => ["Evergreen Oak"] } }

        it "falls back to the base name and titleizes it" do
          expect(plant.display_name).to eq("Quercus Rotundifolia")
        end
      end

      context "when translated name contains nil values" do
        let(:translated_name) { { "fr" => [nil] } }

        it "falls back to the base name and titleizes it" do
          expect(plant.display_name).to eq "Quercus Rotundifolia"
        end
      end
    end
  end
end
