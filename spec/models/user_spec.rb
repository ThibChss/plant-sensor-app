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

  describe 'methods' do
    describe '#full_name' do
      let(:user) { build(:user, first_name: 'Jean', last_name: 'Dupont') }

      it 'joins first_name and last_name with a space' do
        expect(user.full_name).to eq('Jean Dupont')
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
