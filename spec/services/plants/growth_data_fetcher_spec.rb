require 'rails_helper'

RSpec.describe Plants::GrowthDataFetcher do
  describe '#call' do
    before do
      allow(Rails.application.credentials).to receive(:gemini).and_return(
        Struct.new(:api_key).new('test-api-key')
      )
    end

    let(:plant) { build(:plant, scientific_name: 'Quercus rotundifolia') }

    let(:result) do
      VCR.use_cassette(cassette_name, match_requests_on: %i[method uri]) do
        fetcher.call
      end
    end

    let(:fetcher) { described_class.new(plant) }

    describe 'success' do
      context 'when Gemini returns valid JSON in the response text' do
        let(:expected_payload) do
          {
            'sowing' => 'autumn',
            'light' => 8,
            'growth_months' => %w[march april],
            'bloom_months' => [],
            'fruit_months' => []
          }
        end
        let(:cassette_name) { 'growth_data_fetcher_success' }

        it 'returns the parsed growth data hash' do
          expect(result).to eq(expected_payload)
        end
      end
    end

    describe 'error' do
      before do
        allow(fetcher).to receive(:sleep)
        allow(Rails.logger).to receive(:error)
      end

      context 'when Gemini returns non-JSON text' do
        let(:cassette_name) { 'growth_data_fetcher_invalid_json' }

        it 'returns nil and logs a JSON parse error' do
          expect(result).to be_nil
          expect(Rails.logger).to have_received(:error).with(/Error parsing Gemini response/)
        end
      end

      context 'when Gemini responds with 429 then succeeds' do
        let(:cassette_name) { 'growth_data_fetcher_retry_after_rate_limit' }

        it 'retries and returns parsed JSON' do
          expect(result).to include('sowing' => 'spring', 'light' => 5)
          expect(fetcher).to have_received(:sleep).with(1)
          expect(Rails.logger).to have_received(:error).with('[Gemini] Rate limit exceeded or network error. Retrying in 1s... (Attempt 1)')
        end
      end
    end
  end
end
