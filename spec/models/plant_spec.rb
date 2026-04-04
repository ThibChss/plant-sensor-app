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
end
