require 'rails_helper'

RSpec.describe Sensor, type: :model do
  let_it_be(:user) { create(:user) }
  let_it_be(:plant) { create(:plant) }

  describe 'associations' do
    it { should belong_to(:user).optional }
    it { should belong_to(:plant).optional }
  end

  describe 'validations' do
    describe 'presence' do
      context 'when uid is nil' do
        let(:sensor) { build(:sensor, user:, plant:, uid: nil) }

        before do
          sensor.define_singleton_method(:generate_uid) { nil }
        end

        it 'is invalid and adds an error on uid' do
          expect(sensor).not_to be_valid
          expect(sensor.errors[:uid]).to be_present
        end
      end

      context 'when secret_key is nil' do
        let(:sensor) { build(:sensor, user:, plant:, secret_key: nil) }

        before do
          sensor.define_singleton_method(:generate_secret_key) { nil }
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
      expect(sensor).to define_enum_for(:environment)
        .with_values(indoor: 'indoor', outdoor: 'outdoor')
        .backed_by_column_of_type(:enum)
    end
  end

  describe 'store accessors' do
    describe 'current_data' do
      let(:moisture_level_percent) { 55 }
      let(:moisture_level_raw) { 3500 }
      let(:temperature) { 19.2 }
      let(:battery_level) { 72 }
      let(:uptime_seconds) { 1000 }
      let(:sensor) do
        build_stubbed(:sensor, user:, plant:,
                               current_data: { moisture_level_percent:, moisture_level_raw:,
                                               temperature:, battery_level:, uptime_seconds: })
      end

      it 'reads moisture_level, temperature, and battery_level from current_data' do
        expect(sensor.moisture_level_percent).to eq(moisture_level_percent)
        expect(sensor.moisture_level_raw).to eq(moisture_level_raw)
        expect(sensor.temperature).to eq(temperature)
        expect(sensor.battery_level).to eq(battery_level)
        expect(sensor.uptime_seconds).to eq(uptime_seconds)
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
    let(:sensor) { create(:sensor, :with_uid_and_secret_key) }
    let(:new_uid) { 'GP-NEWXX-NEWXX' }
    let(:new_secret) { 'gpm_sk__newreadonlysecretkeyfortestsensorreadonly' }

    it 'does not change uid after create' do
      expect { sensor.update!(uid: new_uid) }.to raise_error(ActiveRecord::ReadonlyAttributeError)
    end

    it 'does not change secret_key after create' do
      expect { sensor.update!(secret_key: new_secret) }.to raise_error(ActiveRecord::ReadonlyAttributeError)
    end
  end

  describe 'scope' do
    describe 'thirsty' do
      let(:thirsty_sensor) { create(:sensor, user:, moisture_threshold: 30, moisture_level_percent: 25) }
      let(:not_thirsty_sensor) { create(:sensor, user:, moisture_threshold: 30, moisture_level_percent: 35) }
      let(:no_moisture_level_sensor) { create(:sensor, user:, plant:, moisture_level_percent: nil) }

      it 'returns sensors with a moisture level below the threshold' do
        expect(Sensor.thirsty).to include(thirsty_sensor)
        expect(Sensor.thirsty).not_to include(not_thirsty_sensor)
        expect(Sensor.thirsty).not_to include(no_moisture_level_sensor)
      end
    end
  end
  describe 'instance methods' do
    describe 'pairable?' do
      context 'when the sensor is unclaimed' do
        let(:sensor) { build(:sensor, user: nil, plant: nil) }

        it 'returns true' do
          expect(sensor.pairable?).to be_truthy
        end
      end

      context 'when the sensor is claimed' do
        let(:sensor) { build(:sensor, user:, plant:) }
        let(:sensor_with_user) { build(:sensor, user:, plant: nil) }
        let(:sensor_with_plant) { build(:sensor, user: nil, plant:) }

        it 'returns false' do
          expect(sensor.pairable?).to be_falsey
          expect(sensor_with_user.pairable?).to be_falsey
          expect(sensor_with_plant.pairable?).to be_falsey
        end
      end
    end

    describe 'qr_code' do
      let(:sensor) { create(:sensor, :with_uid_and_secret_key) }

      it 'returns a QR code' do
        expect(sensor.qr_code).to be_a(RQRCode::QRCode)
      end
    end

    describe 'moisture_level_present?' do
      context 'when the moisture level is present' do
        let(:sensor) { build(:sensor, user:, plant:, moisture_level_percent: 50) }

        it 'returns true' do
          expect(sensor.moisture_level_present?).to be_truthy
        end
      end

      context 'when the moisture level is not present' do
        let(:sensor) { build(:sensor, user:, plant:, moisture_level_percent: nil) }

        it 'returns false' do
          expect(sensor.moisture_level_present?).to be_falsey
        end
      end
    end

    describe 'thirsty?' do
      context 'when the moisture level is below the threshold' do
        let(:sensor) { build(:sensor, user:, plant:, moisture_level_percent: 25) }

        it 'returns true' do
          expect(sensor.thirsty?).to be_truthy
        end
      end

      context 'when the moisture level is not present' do
        let(:sensor) { build(:sensor, user:, plant:, moisture_level_percent: nil) }

        it 'returns false' do
          expect(sensor.thirsty?).to be_falsey
        end
      end

      context 'when the moisture level is above the threshold' do
        let(:sensor) { build(:sensor, user:, plant:, moisture_level_percent: 35) }

        it 'returns false' do
          expect(sensor.thirsty?).to be_falsey
        end
      end
    end
  end
end
