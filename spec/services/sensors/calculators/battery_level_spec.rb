require 'rails_helper'

RSpec.describe Sensors::Calculators::BatteryLevel do
  describe '.compute' do
    subject(:result) { described_class.compute(sensor, battery_level_raw) }

    let(:sensor) { build(:sensor) }
    let(:battery_level_raw) { 3000 }

    # Formula: (raw - 0) / (4095 - 0) * 100, clamped to 0..100, rounded to 1 decimal
    it 'converts the raw ADC value to a 0-100% battery reading' do
      # 3000 / 4095 * 100 = 73.26... → 73.3
      expect(result).to eq(73.3)
    end

    context 'when the raw value is empty (0)' do
      let(:battery_level_raw) { 0 }

      it { is_expected.to eq(0.0) }
    end

    context 'when the raw value is full (4095)' do
      let(:battery_level_raw) { 4095 }

      it { is_expected.to eq(100.0) }
    end

    context 'when the raw value exceeds the maximum' do
      let(:battery_level_raw) { 5000 }

      it 'clamps to 100.0%' do
        expect(result).to eq(100.0)
      end
    end

    context 'when the raw value is negative' do
      let(:battery_level_raw) { -100 }

      it 'clamps to 0.0%' do
        expect(result).to eq(0.0)
      end
    end
  end
end
