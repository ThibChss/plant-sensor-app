require 'rails_helper'

RSpec.describe Sensor, type: :model do
  let_it_be(:user) { create(:user) }
  let_it_be(:plant) { create(:plant) }

  describe 'associations' do
    it { should belong_to(:user) }
    it { should belong_to(:plant) }
  end

  describe 'validations' do
    describe 'presence' do
      subject { build_stubbed(:sensor, user:, plant:) }

      it { should validate_presence_of(:user_id) }
      it { should validate_presence_of(:plant_id) }

      context 'when uid is nil' do
        let(:sensor) { build(:sensor, user:, plant:, uid: nil) }

        around do |example|
          Sensor.skip_callback(:validation, :before, :generate_uid, on: :create, raise: false)
          example.run
          Sensor.set_callback(:validation, :before, :generate_uid, on: :create)
        end

        it 'is invalid and adds an error on uid' do
          expect(sensor).not_to be_valid
          expect(sensor.errors[:uid]).to be_present
        end
      end

      context 'when secret_key is nil' do
        let(:sensor) { build(:sensor, user:, plant:, secret_key: nil) }

        around do |example|
          Sensor.skip_callback(:validation, :before, :generate_secret_key, on: :create, raise: false)
          example.run
          Sensor.set_callback(:validation, :before, :generate_secret_key, on: :create)
        end

        it 'is invalid and adds an error on secret_key' do
          expect(sensor).not_to be_valid
          expect(sensor.errors[:secret_key]).to be_present
        end
      end
    end

    describe 'uniqueness' do
      describe 'uid' do
        let(:shared_uid) { 'GP-SCOPE-SCOPE' }
        let!(:existing_sensor) { create(:sensor, :with_secret_key, :with_uid, user:, plant:, uid: shared_uid) }
        let(:duplicate) { build(:sensor, :with_secret_key, :with_uid, user:, plant:, uid: shared_uid) }

        around do |example|
          Sensor.skip_callback(:validation, :before, :generate_secret_key, on: :create, raise: false)
          Sensor.skip_callback(:validation, :before, :generate_uid, on: :create, raise: false)
          example.run
          Sensor.set_callback(:validation, :before, :generate_secret_key, on: :create)
          Sensor.set_callback(:validation, :before, :generate_uid, on: :create)
        end

        context 'when another sensor on the same plant reuses the uid' do
          it 'is invalid and adds an error on uid' do
            expect(duplicate).not_to be_valid
            expect(duplicate.errors[:uid]).to be_present
          end
        end

      end

      describe 'secret_key' do
        let(:shared_secret) { 'gpm_sk__sharedsecretforuniquenesstestsensorkey' }
        let!(:existing_sensor) { create(:sensor, :with_uid, user:, plant:, secret_key: shared_secret) }
        let(:duplicate) { build(:sensor, :with_uid, user:, plant:, secret_key: shared_secret) }

        around do |example|
          Sensor.skip_callback(:validation, :before, :generate_secret_key, on: :create, raise: false)
          Sensor.skip_callback(:validation, :before, :generate_uid, on: :create, raise: false)
          example.run
          Sensor.set_callback(:validation, :before, :generate_secret_key, on: :create)
          Sensor.set_callback(:validation, :before, :generate_uid, on: :create)
        end

        it 'is invalid when secret_key matches an existing sensor' do
          expect(duplicate).not_to be_valid
          expect(duplicate.errors[:secret_key]).to be_present
        end
      end
    end
  end

  describe 'enums' do
    let(:sensor) { build_stubbed(:sensor, user:, plant:) }

    it do
      expect(sensor).to define_enum_for(:location)
        .with_values(indoor: 'indoor', outdoor: 'outdoor')
        .backed_by_column_of_type(:enum)
    end
  end

  describe 'store accessors' do
    describe 'current_data' do
      let(:moisture_level) { 55 }
      let(:temperature) { 19.2 }
      let(:battery_level) { 72 }
      let(:sensor) do
        build_stubbed(:sensor, user:, plant:,
                               current_data: { moisture_level:, temperature:, battery_level: })
      end

      it 'reads moisture_level, temperature, and battery_level from current_data' do
        expect(sensor.moisture_level).to eq(moisture_level)
        expect(sensor.temperature).to eq(temperature)
        expect(sensor.battery_level).to eq(battery_level)
      end
    end
  end

  describe 'callbacks' do
    describe 'on create' do
      let(:sensor) { build(:sensor, :with_uid_and_secret_key, user:, plant:) }

      it 'assigns a uid with the expected prefix and shape' do
        expect(sensor.uid).to match(/\AGP-[A-Z0-9]{5}-[A-Z0-9]{5}\z/)
      end

      it 'assigns a secret_key with the expected prefix' do
        expect(sensor.secret_key).to match(/\Agpm_sk__[A-Za-z0-9]{36}\z/)
      end
    end
  end

  describe 'readonly attributes' do
    let(:sensor) { create(:sensor, user:, plant:) }
    let(:new_uid) { 'GP-NEWXX-NEWXX' }
    let(:new_secret) { 'gpm_sk__newreadonlysecretkeyfortestsensorreadonly' }

    it 'does not change uid after create' do
      expect { sensor.update!(uid: new_uid) }.to raise_error(ActiveRecord::ReadonlyAttributeError)
    end

    it 'does not change secret_key after create' do
      expect { sensor.update!(secret_key: new_secret) }.to raise_error(ActiveRecord::ReadonlyAttributeError)
    end
  end
end
