require 'rails_helper'

RSpec.describe Sensors::MeasurementProcessor do
  describe '.call' do
    subject(:service) { described_class.call(sensor_id, data) }

    let_it_be(:sensor, refind: true) do
      create(:sensor, :with_valid_keys, :with_user,
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

    # ─────────────────────────────────────────────
    # Authentication
    # ─────────────────────────────────────────────
    context 'when sensor_id is blank' do
      let(:sensor_id) { nil }

      it 'returns unauthorized without touching the database' do
        expect { service }.not_to(change { sensor.reload.last_seen_at })

        expect(service.status).to eq(:unauthorized)
        expect(service.message).to eq(error: 'Access denied: Invalid UID or Secret Key')
      end
    end

    # ─────────────────────────────────────────────
    # Payload validation
    # ─────────────────────────────────────────────
    context 'when the payload is missing uptime_seconds' do
      let(:data) { { moisture_level_raw: 1515 } }

      it 'returns unprocessable_content' do
        expect(service.status).to eq(:unprocessable_content)
        expect(service.message[:error]).to eq(
          '[MeasurementProcessor] Unable to process measurement data: Missing required data: moisture_level_raw and uptime_seconds'
        )
      end
    end

    context 'when the payload is empty' do
      let(:data) { {} }

      it 'returns unprocessable_content' do
        expect(service.status).to eq(:unprocessable_content)
        expect(service.message[:error]).to eq(
          '[MeasurementProcessor] Unable to process measurement data: Missing required data: moisture_level_raw and uptime_seconds'
        )
      end
    end

    # ─────────────────────────────────────────────
    # Successful processing
    # ─────────────────────────────────────────────
    context 'with a valid sensor and payload' do
      context 'without a plant' do
        let(:timestamp) { Time.zone.parse('2026-04-19 12:00:00') }

        before do
          allow(Time).to receive(:current).and_return(timestamp)
          sensor.update!(last_seen_at: 1.hour.ago)
        end

        it 'returns success' do
          expect(service.status).to eq(:ok)
          expect(service.message).to eq(message: 'Data saved successfully')
        end

        it 'updates moisture, uptime, last_seen_at and preserves other sensor data' do
          service

          expect(sensor.reload.moisture_level_percent).to eq(46.5)
          expect(sensor.moisture_level_raw.to_f).to eq(2675.0)
          expect(sensor.uptime_seconds).to eq(2000)
          expect(sensor.temperature).to eq(18.0)
          expect(sensor.battery_level).to eq(50)
          expect(sensor.last_seen_at).to eq(timestamp)
        end
      end

      context 'with a plant' do
        let(:sensor_with_plant) do
          create(:sensor, :with_valid_keys, :with_user_and_plant,
                 current_data: {
                   moisture_level_percent: 10.0,
                   moisture_level_raw: 3500.0,
                   temperature: 18.0,
                   battery_level: 50,
                   uptime_seconds: 1000
                 })
        end

        let(:sensor_id) { sensor_with_plant.id }

        it 'returns a plant-relative moisture percent' do
          expect(service.status).to eq(:ok)
          expect(sensor_with_plant.reload.moisture_level_percent).not_to eq(46.5)
        end
      end

      context 'when the sensor is not yet linked to a user or plant' do
        before { sensor.update!(user: nil, plant: nil) }

        it 'still accepts measurements (hardware may report before app setup)' do
          expect(service.status).to eq(:ok)
          expect(sensor.reload.moisture_level_raw.to_f).to eq(2675.0)
          expect(sensor.uptime_seconds).to eq(2000)
        end
      end
    end

    # ─────────────────────────────────────────────
    # Watering event detection
    # ─────────────────────────────────────────────
    context 'with watering event detection' do
      let(:timestamp) { Time.zone.parse('2026-04-19 12:00:00') }
      let(:last_watered_at) { Time.zone.parse('2026-04-19 11:00:00') }

      before { allow(Time).to receive(:current).and_return(timestamp) }

      context 'when the sensor has no previous readings' do
        it 'does not detect a watering event' do
          expect(service.status).to eq(:ok)
          expect(sensor.reload.last_watered_at).to be_nil
        end
      end

      context 'when the moisture spike is exactly at the threshold' do
        let(:data) { { moisture_level_raw: 1340, uptime_seconds: 2000 } }
        let!(:sensor_reading) { create(:sensor_reading, sensor:, moisture_level_percent: 80.0) }

        it 'detects a watering event (100.0 - 80.0 = 20.0, exactly at threshold)' do
          service

          expect(sensor.reload.last_watered_at).to eq(timestamp)
          expect(sensor.readings.last.watering_event).to be_truthy
        end
      end

      context 'when the moisture spike is above the threshold' do
        let(:data) { { moisture_level_raw: 1340, uptime_seconds: 2000 } }
        let!(:sensor_reading) { create(:sensor_reading, sensor:, moisture_level_percent: 79.9) }

        # 100.0 - 79.9 = 20.1 → above SPIKE_THRESHOLD of 20

        context 'when last_watered_at was nil' do
          it 'sets last_watered_at and marks the reading as a watering event' do
            expect(sensor.last_watered_at).to be_nil

            expect(service.status).to eq(:ok)
            expect(sensor.reload.last_watered_at).to eq(timestamp)
            expect(sensor.readings.last.watering_event).to be_truthy
          end
        end

        context 'when last_watered_at was already set' do
          before { sensor.update!(last_watered_at:) }

          it 'updates last_watered_at to the new timestamp' do
            expect(sensor.last_watered_at).to eq(last_watered_at)

            expect(service.status).to eq(:ok)
            expect(sensor.reload.last_watered_at).to eq(timestamp)
            expect(sensor.readings.last.watering_event).to be_truthy
          end
        end
      end

      context 'when no watering event is detected' do
        let!(:sensor_reading) { create(:sensor_reading, sensor:, moisture_level_percent: 46.5) }

        context 'when last_watered_at was nil' do
          it 'keeps last_watered_at as nil' do
            expect(service.status).to eq(:ok)
            expect(sensor.reload.last_watered_at).to be_nil
            expect(sensor.readings.last.watering_event).to be_falsey
          end
        end

        context 'when last_watered_at was already set' do
          before { sensor.update!(last_watered_at:) }

          it 'preserves the existing last_watered_at' do
            expect(service.status).to eq(:ok)
            expect(sensor.reload.last_watered_at).to eq(last_watered_at)
            expect(sensor.readings.last.watering_event).to be_falsey
          end
        end
      end
    end

    # ─────────────────────────────────────────────
    # Moisture low notification
    # ─────────────────────────────────────────────
    context 'with moisture low notification' do
      before { allow(Notifications::Deliverer).to receive(:notify!) }

      context 'when the sensor is thirsty (moisture below threshold)' do
        before { sensor.update!(moisture_threshold: 50) }

        context 'and no prior MoistureLow notification exists for this last_watered_at' do
          it 'notifies the user with :moisture_low and :warning flash' do
            service

            expect(Notifications::Deliverer).to have_received(:notify!).with(
              hash_including(
                notification_type: :moisture_low,
                flash_type: :warning,
                notifiable: sensor
              )
            )
          end

          it 'passes the sensor last_watered_at in data' do
            service

            expect(Notifications::Deliverer).to have_received(:notify!).with(
              hash_including(data: { last_watered_at: sensor.reload.last_watered_at })
            )
          end
        end

        context 'and a MoistureLow notification already exists for this last_watered_at' do
          let(:last_watered_at) { Time.zone.parse('2026-04-10 08:00:00') }

          before do
            sensor.update!(last_watered_at:)

            Notifications::MoistureLow.create!(
              user: sensor.user,
              notifiable: sensor,
              data: { last_watered_at: last_watered_at.as_json, via: 'flash', message: 'low' }
            )
          end

          it 'does not notify again (deduplication)' do
            service

            expect(Notifications::Deliverer).not_to have_received(:notify!)
          end
        end
      end

      context 'when the sensor is not thirsty (moisture above threshold)' do
        before { sensor.update!(moisture_threshold: 20) }

        it 'does not notify' do
          service

          expect(Notifications::Deliverer).not_to have_received(:notify!)
        end
      end
    end

    # ─────────────────────────────────────────────
    # Error handling
    # ─────────────────────────────────────────────
    context 'when update! raises RecordInvalid' do
      before do
        allow_any_instance_of(Sensor).to receive(:update!)
          .and_raise(ActiveRecord::RecordInvalid.new(sensor))
      end

      it 'returns unprocessable_content' do
        expect(service.status).to eq(:unprocessable_content)
        expect(service.message[:error]).to include(
          '[MeasurementProcessor] Unable to process measurement data:'
        )
      end
    end
  end
end
