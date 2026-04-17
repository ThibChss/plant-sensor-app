require 'rails_helper'

RSpec.describe Sensors::UidValidator do
  let_it_be(:user) { create(:user) }
  let(:session) { instance_double(Session, user:) }

  before do
    Current.session = session
  end

  describe '.call' do
    subject(:result) { described_class.call(uid) }

    context 'when uid is blank' do
      ['', '   ', nil].each do |value|
        context "with #{value.inspect}" do
          let(:uid) { value }

          it 'returns not ok with the blank message' do
            expect(result.ok).to be(false)
            expect(result.message).to eq(I18n.t('sensors.setup.uid_validation.blank'))
          end
        end
      end
    end

    context 'when uid does not match GP-XXXXX-XXXXX' do
      let(:uid) { 'GP-1234-ABCDE' }

      it 'returns not ok with the format message' do
        expect(result.ok).to be(false)
        expect(result.message).to eq(I18n.t('sensors.setup.uid_validation.invalid_format'))
      end
    end

    context 'when uid is well formed but no unclaimed sensor exists' do
      let(:uid) { 'GP-ZZZZZ-ZZZZZ' }

      it 'returns not ok with the unavailable message' do
        expect(result.ok).to be(false)
        expect(result.message).to eq(I18n.t('sensors.setup.uid_validation.unavailable'))
      end
    end

    context 'when uid matches an unclaimed sensor (user_id nil)' do
      let!(:sensor) { create(:sensor, :with_uid_and_secret_key, user: nil, plant: nil) }
      let(:uid) { sensor.uid }

      it 'returns ok' do
        expect(result.ok).to be(true)
        expect(result.sensor).to eq(sensor)
        expect(result.message).to be_nil
      end
    end

    context 'when uid matches a sensor already linked to the current user without a plant' do
      let!(:sensor) { create(:sensor, :with_uid_and_secret_key, user:, plant: nil) }
      let(:uid) { sensor.uid }

      it 'returns ok' do
        expect(result.ok).to be(true)
        expect(result.sensor).to eq(sensor)
        expect(result.message).to be_nil
      end
    end

    context 'when uid matches a sensor already linked to another user without a plant' do
      let!(:sensor) { create(:sensor, :with_uid_and_secret_key, user: build(:user), plant: nil) }
      let(:uid) { sensor.uid }

      it 'returns not ok with the unavailable message' do
        expect(result.ok).to be(false)
        expect(result.message).to eq(I18n.t('sensors.setup.uid_validation.unavailable'))
      end
    end
  end
end
