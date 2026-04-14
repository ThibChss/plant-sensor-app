# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Sensors::DataTracker do
  include ActiveSupport::Testing::TimeHelpers

  let_it_be(:sensor, refind: true) { create(:sensor) }

  before do
    travel_to(Time.zone.parse('2026-04-15 12:00:00'))
  end

  after do
    travel_back
  end

  let(:date_param) { '7d' }

  subject(:tracker) { described_class.new(sensor, date_param) }

  describe '#stats' do
    context 'with no readings in range' do
      it 'returns zeroed stats' do
        expect(tracker.stats).to eq(average: 0, min: 0, max: 0)
      end
    end

    context 'with readings in range' do
      let_it_be(:readings) do
        create(:sensor_reading, sensor:, moisture_level_percent: 40.0, created_at: 5.days.ago)
        create(:sensor_reading, sensor:, moisture_level_percent: 55.5, created_at: 2.days.ago)
        create(:sensor_reading, sensor:, moisture_level_percent: 70.0, created_at: 1.day.ago)
      end

      it 'returns average, min, and max rounded to one decimal' do
        expect(tracker.stats[:average]).to eq(55.2)
        expect(tracker.stats[:min]).to eq(40.0)
        expect(tracker.stats[:max]).to eq(70.0)
      end

      it 'ignores readings older than the window' do
        create(:sensor_reading, sensor:, moisture_level_percent: 10.0, created_at: 10.days.ago)

        expect(tracker.stats[:min]).to eq(40.0)
      end
    end
  end

  describe '#chart_data' do
    context "with param '7d'" do
      before do
        create(:sensor_reading, sensor:, moisture_level_percent: 50.0, created_at: Time.zone.parse('2026-04-14 08:00:00'))
        create(:sensor_reading, sensor:, moisture_level_percent: 30.0, created_at: Time.zone.parse('2026-04-14 20:00:00'))
        create(:sensor_reading, sensor:, moisture_level_percent: 60.0, created_at: Time.zone.parse('2026-04-13 10:00:00'))
      end

      it 'returns one point per distinct timestamp bucket with averaged y' do
        expect(tracker.chart_data).to all(include(:x, :y))

        day_fourteen = tracker.chart_data.select { it[:x].include?('04-14') }
        expect(day_fourteen.size).to eq(2)
        expect(day_fourteen.pluck(:y)).to contain_exactly(50.0, 30.0)
      end
    end

    context "with param '30d'" do
      before do
        create(:sensor_reading, sensor:, moisture_level_percent: 40.0, created_at: Time.zone.parse('2026-04-10 12:00:00'))
        create(:sensor_reading, sensor:, moisture_level_percent: 60.0, created_at: Time.zone.parse('2026-04-10 18:00:00'))
        create(:sensor_reading, sensor:, moisture_level_percent: 80.0, created_at: Time.zone.parse('2026-04-12 09:00:00'))
      end

      let(:date_param) { '30d' }

      it 'groups by calendar day and averages moisture per day' do
        expect(tracker.chart_data).to all(include(:x, :y))
        expect(tracker.chart_data.pluck(:y)).to contain_exactly(50.0, 80.0)
      end
    end

    context "with param '3m'" do
      before do
        create(:sensor_reading, sensor:, moisture_level_percent: 10.0, created_at: Time.zone.parse('2026-04-14 12:00:00'))
        create(:sensor_reading, sensor:, moisture_level_percent: 20.0, created_at: Time.zone.parse('2026-03-01 12:00:00'))
      end

      let(:date_param) { '3m' }

      it 'returns chart points keyed by week bucket' do
        expect(tracker.chart_data).to all(include(:x, :y))
        expect(tracker.chart_data.pluck(:y)).to contain_exactly(10.0, 20.0)
      end
    end

    context "with param '6m'" do
      before do
        create(:sensor_reading, sensor:, moisture_level_percent: 80.0, created_at: Time.zone.parse('2026-02-05 12:00:00'))
        create(:sensor_reading, sensor:, moisture_level_percent: 60.0, created_at: Time.zone.parse('2026-02-20 12:00:00'))
      end

      let(:date_param) { '6m' }

      it 'groups by month start and averages readings in the same month' do
        expect(tracker.chart_data).to all(include(:x, :y))
        expect(tracker.chart_data.pluck(:y)).to contain_exactly(70.0)
        expect(tracker.chart_data.pluck(:x)).to include(/2026-02/)
      end
    end
  end
end
