require 'rails_helper'

RSpec.describe Sensors::MeasurementProcessor do
  describe '.call' do
    let_it_be(:sensor, refind: true) do
      create(:sensor, :with_uid_and_secret_key, :with_user_and_plant,
             current_data: {
               moisture_level_percent: 10.0,
               moisture_level_raw: 3500.0,
               temperature: 18.0,
               battery_level: 50,
               uptime_seconds: 1000
             })
    end
    let(:sensor_id) { sensor.id }
    let(:data) do
      {
        moisture_level_raw: 2675,
        uptime_seconds: 2000
      }
    end

    subject(:service) { described_class.call(sensor_id, data) }

    context 'when sensor_id is blank' do
      let(:sensor_id) { nil }

      it 'returns unauthorized without touching the database' do
        expect { service }.not_to(change { sensor.reload.last_seen_at })

        expect(service.status).to eq(:unauthorized)
        expect(service.message).to eq(error: 'Access denied: Invalid UID or Secret Key')
      end
    end

    context 'with a matching sensor and full payload' do
      it 'returns success and updates last_seen_at, moisture, and uptime' do
        expect(service.status).to eq(:ok)
        expect(service.message).to eq(message: 'Data saved successfully')

        expect(sensor.reload.moisture_level_percent).to eq(50.0)
        expect(sensor.moisture_level_raw.to_f).to eq(2675.0)
        expect(sensor.uptime_seconds).to eq(2000)
        expect(sensor.temperature).to eq(18.0)
        expect(sensor.battery_level).to eq(50)

        expect(sensor.last_seen_at).to be_present
      end
    end

    context 'when the sensor is not yet linked to a user or plant' do
      let_it_be(:unclaimed_sensor, refind: true) do
        create(:sensor, :with_uid_and_secret_key, user: nil, plant: nil)
      end

      let(:sensor_id) { unclaimed_sensor.id }

      it 'still accepts measurements (hardware may report before app setup)' do
        expect(service.status).to eq(:ok)
        expect(unclaimed_sensor.reload.moisture_level_raw.to_f).to eq(2675.0)
        expect(unclaimed_sensor.uptime_seconds).to eq(2000)
      end
    end

    context 'when only moisture_level_raw is present' do
      let(:data) { { moisture_level_raw: 1515 } }

      it 'returns unprocessable_content with the error message' do
        expect(service.status).to eq(:unprocessable_content)
        expect(service.message[:error]).to eq('Internal error: Missing required data: moisture_level_raw and uptime_seconds')
      end
    end

    context 'when update! raises RecordInvalid' do
      before do
        allow_any_instance_of(Sensor).to receive(:update!)
          .and_raise(ActiveRecord::RecordInvalid.new(sensor))
      end

      it 'returns unprocessable_content with the error message' do
        expect(service.status).to eq(:unprocessable_content)
        expect(service.message[:error]).to start_with('Internal error:')
      end
    end
  end
end
