require 'rails_helper'

RSpec.describe User, type: :model do
  describe 'validations' do
    describe 'presence' do
      subject { build(:user) }

      it { should validate_presence_of(:first_name) }
      it { should validate_presence_of(:last_name) }
      it { should validate_presence_of(:email_address) }
      it { should validate_presence_of(:password) }
    end

    describe 'uniqueness' do
      subject { build(:user) }

      it { should validate_uniqueness_of(:email_address).ignoring_case_sensitivity }
    end

    describe 'email_address format' do
      subject { build(:user) }

      it { should allow_value('user@example.com').for(:email_address) }
      it { should_not allow_value('not-an-email').for(:email_address) }
    end
  end

  describe 'normalizations' do
    let(:user) { build(:user, email_address: '  Jane@EXAMPLE.COM  ') }

    it 'strips and downcases email_address' do
      expect(user).to be_valid
      expect(user.email_address).to eq('jane@example.com')
    end
  end

  describe 'associations' do
    it { should have_many(:sessions).dependent(:destroy) }
    it { should have_many(:sensors).dependent(:destroy) }
    it { should have_many(:plants).through(:sensors) }
    it { should have_many(:push_subscriptions).dependent(:destroy) }
  end

  describe 'methods' do
    describe '#full_name' do
      let(:user) { build(:user, first_name: 'Jean', last_name: 'Dupont') }

      it 'joins first_name and last_name with a space' do
        expect(user.full_name).to eq('Jean Dupont')
      end
    end

    describe '#notify' do
      let_it_be(:user, reload: true) { create(:user) }

      it 'delegates to Notifications::Deliverer.notify! with message nil by default' do
        expect(Notifications::Deliverer).to receive(:notify!).with(
          user:,
          message: nil,
          notification_type: :sensor_connected,
          flash_type: :notice,
          notifiable: nil,
          data: {}
        )

        user.notify(notification_type: :sensor_connected)
      end

      it 'forwards an explicit message when provided' do
        expect(Notifications::Deliverer).to receive(:notify!).with(
          hash_including(message: 'Hello!')
        )

        user.notify(message: 'Hello!', notification_type: :sensor_connected)
      end

      context 'when delivery fails' do
        it 'raises Notifications::Deliverer::DeliveryError' do
          expect(Notifications::Deliverer).to receive(:notify!).and_raise(Notifications::Deliverer::DeliveryError)

          expect { user.notify(notification_type: :nonexistent_type) }.to raise_error(Notifications::Deliverer::DeliveryError)
        end
      end
    end

    describe '#active?' do
      let(:user) { build(:user, last_seen_at:) }

      context 'when last_seen_at is within 2 minutes' do
        let(:last_seen_at) { 1.minute.ago }

        it 'returns true' do
          freeze_time { expect(user.active?).to be true }
        end
      end

      context 'when last_seen_at is older than 2 minutes' do
        let(:last_seen_at) { 3.minutes.ago }

        it 'returns false' do
          freeze_time { expect(user.active?).to be false }
        end
      end

      context 'when last_seen_at is exactly 2 minutes ago' do
        let(:last_seen_at) { 2.minutes.ago }

        it 'returns false' do
          freeze_time { expect(user.active?).to be false }
        end
      end
    end

    describe '#initials' do
      context 'when first_name and last_name are lowercase' do
        let(:user) { build(:user, first_name: 'jean', last_name: 'dupont') }

        it 'returns the first character of each name in uppercase' do
          expect(user.initials).to eq('JD')
        end
      end

      context 'when first_name and last_name are uppercase' do
        let(:user) { build(:user, first_name: 'Marie', last_name: 'Curie') }

        it 'leaves uppercase initials unchanged' do
          expect(user.initials).to eq('MC')
        end
      end
    end
  end
end
