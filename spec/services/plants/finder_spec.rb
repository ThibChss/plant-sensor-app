require 'rails_helper'

RSpec.describe Plants::Finder do
  describe '#call' do
    let(:fixture_path) { Rails.root.join('spec/fixtures/files/plants_for_finder.json') }

    subject(:finder_results) { described_class.call(query:) }

    before do
      stub_const('Plants::Finder::JSON_FILE_PATH', fixture_path)
    end

    after do
      Plants::Finder.reload!
    end

    shared_examples 'returns an empty array' do
      it 'returns an empty array' do
        expect(finder_results).to eq([])
      end
    end

    shared_examples 'returns one result' do |key, expected_value|
      it 'returns the expected results' do
        expect(finder_results.size).to eq(1)
        expect(finder_results.first[key]).to eq(expected_value)
      end
    end

    context 'when query is nil' do
      let(:query) { nil }

      include_examples 'returns an empty array'
    end

    context 'when query is blank after strip' do
      let(:query) { '   ' }

      include_examples 'returns an empty array'
    end

    context 'when query is shorter than 3 characters' do
      let(:query) { 'ab' }

      include_examples 'returns an empty array'
    end

    context 'when query has fewer than 3 non-space characters but is padded' do
      let(:query) { '  ab  ' }

      include_examples 'returns an empty array'
    end

    context 'when query matches a plant name (case-insensitive)' do
      let(:query) { 'SNAKE' }

      include_examples 'returns one result', 'name', 'Snake Plant'
    end

    context 'when query matches a scientific name' do
      let(:query) { 'nephrolepis' }

      include_examples 'returns one result', 'scientific_name', 'Nephrolepis exaltata'
    end

    context 'when query matches a translated_name en entry' do
      let(:query) { 'mother' }

      include_examples 'returns one result', 'name', 'Snake Plant'
    end

    context 'when query matches a translated_name fr entry' do
      let(:query) { 'serpent' }

      include_examples 'returns one result', 'name', 'Snake Plant'
    end

    context 'when query matches nothing' do
      let(:query) { 'xyz' }

      include_examples 'returns an empty array'
    end

    context 'when more than ten plants match' do
      let(:fixture_path) { Rails.root.join('spec/fixtures/files/plants_for_finder_many_matches.json') }
      let(:query) { 'match' }

      it 'returns at most ten plants' do
        expect(finder_results.size).to eq(10)
      end
    end
  end
end
