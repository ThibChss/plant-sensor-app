module Seed
  class UserPlantsAssociator < ApplicationService
    def call
      associate_plants!
    end

    private

    def associate_plants!
      plants_to_associate.each do |plant|
        SensorCreator.call(user:, plant:, need_water: need_water?)
      end
    end

    def plants_to_associate
      @plants_to_associate ||= plants.sample(4).push(special_plant).shuffle
    end

    def plants
      @plants ||= Plant.where("growth_data->'min_soil_moisture'->>'indoor' IS NOT NULL")
    end

    def special_plant
      @special_plant ||= Plant.find_by(trefle_id: "126118")
    end

    def need_water?
      [false, true].sample
    end

    def user
      @user ||= User.create!(
        first_name: "Thibault",
        last_name: "Chassine",
        email_address: "thib@gmail.com",
        password: "password"
      )
    end
  end
end
