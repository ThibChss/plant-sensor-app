module Seed
  class CopyDbToJson < ApplicationService
    def initialize
      @plants = Plant.all
      @file_path = Rails.root.join('db', 'plants.json')
    end

    def call
      File.write(@file_path, JSON.pretty_generate(@plants.as_json(except: %i[created_at updated_at])))
    end
  end
end
