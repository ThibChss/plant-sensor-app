require 'rails_helper'

RSpec.describe Notification, type: :model do
  before do
    allow_any_instance_of(Notification).to receive(:set_message).and_return(true)
  end

  describe 'associations' do
    it { should belong_to(:user) }
    it { should belong_to(:notifiable).optional }
  end

  describe 'validations' do
    subject { build(:notification) }

    it { should validate_presence_of(:type) }
  end

  describe 'scopes' do
    let_it_be(:user) { create(:user) }

    let(:unread_notification) { create(:notification, user:) }
    let(:read_notification)   { create(:notification, :read, user:) }

    describe '.unread' do
      it 'returns only notifications without a read_at' do
        expect(described_class.unread).to include(unread_notification)
        expect(described_class.unread).not_to include(read_notification)
      end
    end
  end

  describe '#read?' do
    context 'when read_at is nil' do
      let(:notification) { build(:notification, read_at: nil) }

      it 'returns false' do
        expect(notification.read?).to be false
      end
    end

    context 'when read_at is set' do
      let(:notification) { build(:notification, :read) }

      it 'returns true' do
        expect(notification.read?).to be true
      end
    end
  end

  describe '#unread?' do
    context 'when read_at is nil' do
      let(:notification) { build(:notification, read_at: nil) }

      it 'returns true' do
        expect(notification.unread?).to be true
      end
    end

    context 'when read_at is set' do
      let(:notification) { build(:notification, :read) }

      it 'returns false' do
        expect(notification.unread?).to be false
      end
    end
  end

  describe '#mark_as_read!' do
    let(:notification) { create(:notification, read_at: nil) }

    it 'sets read_at to the current time' do
      freeze_time do
        notification.mark_as_read!

        expect(notification.reload.read_at).to eq(Time.current)
      end
    end
  end
end
