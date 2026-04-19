require 'rails_helper'

RSpec.describe Sensors::MoistureLevelCalculator do
  describe '.compute' do
    subject(:result) { described_class.compute(sensor, moisture_level_raw) }

    let(:moisture_level_raw) { 2675 }
    let(:sensor) { build(:sensor, environment: 'indoor', last_watered_at: nil, plant: nil) }

    # ─────────────────────────────────────────────
    # Step 1 — Base moisture (no plant associated)
    # Formula: (DRY - raw) / (DRY - WET) * 100
    # DRY = 3835, WET = 1340
    # ─────────────────────────────────────────────
    context 'without a plant' do
      it 'converts the raw ADC value to a 0-100% moisture reading' do
        # (3835 - 2675) / (3835 - 1340) * 100 = 46.5
        expect(result).to eq(46.5)
      end

      context 'when the sensor reads the dry calibration value' do
        let(:moisture_level_raw) { 3835 }

        it { is_expected.to eq(0.0) }
      end

      context 'when the sensor reads the wet calibration value' do
        let(:moisture_level_raw) { 1340 }

        it { is_expected.to eq(100.0) }
      end

      context 'when the raw value exceeds the dry limit' do
        let(:moisture_level_raw) { 4000 }

        it 'clamps to 0.0' do
          expect(result).to eq(0.0)
        end
      end

      context 'when the raw value is below the wet limit' do
        let(:moisture_level_raw) { 1000 }

        it 'clamps to 100.0' do
          expect(result).to eq(100.0)
        end
      end

      context 'when the sensor has no environment set' do
        let(:sensor) { build(:sensor, environment: nil, last_watered_at: nil, plant: nil) }

        it 'still returns the base moisture without error' do
          expect(result).to eq(46.5)
        end
      end
    end

    # ─────────────────────────────────────────────
    # Step 2 — Plant-relative moisture (with plant)
    # Rescales base percentage to the plant's ideal range:
    # target = (base - min) / (max - min) * 100
    # 0% = at plant minimum, 100% = at plant maximum
    # ─────────────────────────────────────────────
    context 'with a plant' do
      let(:plant) do
        build(:plant, growth_data: {
                'min_soil_moisture' => { 'indoor' => 40, 'outdoor' => 40 },
                'max_soil_moisture' => { 'indoor' => 80, 'outdoor' => 80 },
                'watering_frequency' => {
                  'indoor' => { 'min_days' => 7, 'max_days' => 14 },
                  'outdoor' => { 'min_days' => 15, 'max_days' => 30 }
                }
              })
      end

      before { sensor.plant = plant }

      context 'without last_watered_at (no decay applied)' do
        it 'scales the base reading relative to the plant moisture range' do
          # base = 46.49...
          # target = (46.49 - 40) / (80 - 40) * 100 = 16.2
          expect(result).to eq(16.2)
        end
      end

      context 'when the base moisture equals the plant minimum' do
        let(:moisture_level_raw) { 2915 } # base ≈ 40%

        it 'returns 0.0 (plant is at its dry threshold)' do
          expect(result).to eq(0.0)
        end
      end

      context 'when the base moisture equals the plant maximum' do
        let(:moisture_level_raw) { 1836 } # base ≈ 80%

        it 'returns 100.0 (plant is at its ideal moisture)' do
          expect(result).to eq(100.0)
        end
      end

      context 'when plant moisture range is not configured' do
        let(:plant) do
          build(:plant, growth_data: {
                  'min_soil_moisture' => {},
                  'max_soil_moisture' => {},
                  'watering_frequency' => {}
                })
        end

        it 'falls back to 0-100% range and returns the base percent' do
          # target = (46.49 - 0) / (100 - 0) * 100 = 46.5
          expect(result).to eq(46.5)
        end
      end

      # ─────────────────────────────────────────────
      # Step 3 — Time decay (with last_watered_at)
      # decay_factor = 1 - (days_since_watered / avg_days)
      # Decays linearly from 1.0 (just watered) to 0.0 (overdue)
      # Can only reduce the value, never increase it
      # ─────────────────────────────────────────────
      context 'with last_watered_at' do
        let(:now) { Time.zone.parse('2026-04-19 12:00:00') }

        before { allow(Time).to receive(:current).and_return(now) }

        context 'when watered today' do
          before { sensor.last_watered_at = now }

          it 'applies no decay (factor = 1.0)' do
            # decay_factor = 1 - (0 / 10.5) = 1.0
            # result = 16.2 * 1.0 = 16.2
            expect(result).to eq(16.2)
          end
        end

        context 'when watered 3 days ago' do
          before { sensor.last_watered_at = now - 3.days }

          it 'applies a partial decay' do
            # avg_days = (7 + 14) / 2 = 10.5
            # decay_factor = 1 - (3 / 10.5) = 0.7142...
            # result = 16.232... * 0.7142... = 11.6
            expect(result).to eq(11.6)
          end
        end

        context 'when watered exactly at the average interval ago' do
          before { sensor.last_watered_at = now - 10.5.days }

          it 'returns 0.0 (fully decayed)' do
            # decay_factor = 1 - (10.5 / 10.5) = 0.0
            expect(result).to eq(0.0)
          end
        end

        context 'when last watered longer ago than the average interval' do
          before { sensor.last_watered_at = now - 15.days }

          it 'clamps the decay factor to 0 and returns 0.0' do
            # decay_factor = 1 - (15 / 10.5) = -0.42... → clamped to 0
            expect(result).to eq(0.0)
          end
        end

        context 'when last_watered_at is in the future' do
          before { sensor.last_watered_at = now + 1.day }

          it 'clamps decay factor to 1.0 and does not exceed target' do
            expect(result).to be <= 16.2
            expect(result).to eq(16.2)
          end
        end

        context 'when watering frequency has nil values' do
          let(:plant) do
            build(:plant, growth_data: {
                    'min_soil_moisture' => { 'indoor' => 40, 'outdoor' => 40 },
                    'max_soil_moisture' => { 'indoor' => 80, 'outdoor' => 80 },
                    'watering_frequency' => {
                      'indoor' => { 'min_days' => nil, 'max_days' => nil },
                      'outdoor' => { 'min_days' => nil, 'max_days' => nil }
                    }
                  })
          end

          before { sensor.last_watered_at = now - 3.days }

          it 'falls back to default watering frequency' do
            # WATERING_FREQUENCY_DEFAULTS indoor: min=7, max=10, avg=8.5
            # decay_factor = 1 - (3 / 8.5) = 0.6470...
            # result = 16.232... * 0.6470... = 10.5
            expect(result).to eq(10.5)
          end
        end
      end

      context 'with an outdoor sensor' do
        let(:sensor) { build(:sensor, :outdoor, last_watered_at: nil, plant: nil) }
        let(:now)    { Time.zone.parse('2026-04-19 12:00:00') }

        before do
          allow(Time).to receive(:current).and_return(now)
          sensor.plant = plant
          sensor.last_watered_at = now - 10.days
        end

        it 'uses the outdoor watering frequency and moisture range' do
          # avg_days = (15 + 30) / 2 = 22.5
          # target (outdoor min=40, max=80) = 16.232...
          # decay_factor = 1 - (10 / 22.5) = 0.5555...
          # result = 16.232... * 0.5555... = 9.0
          expect(result).to eq(9.0)
        end
      end

      context 'when sensor has no environment set' do
        let(:sensor) { build(:sensor, environment: nil, last_watered_at: nil, plant: nil) }

        before { sensor.plant = plant }

        it 'defaults to indoor environment for both range and frequency' do
          expect(result).to eq(16.2)
        end
      end
    end
  end
end
