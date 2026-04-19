module Seed
  class SensorCreator < ApplicationService
    PLANT_NICKNAMES = [
      "Green Buddy",
      "Leafy Pal",
      "Sprouty",
      "Sun Chaser",
      "Mossy",
      "Rooty",
      "Petal Pop",
      "Stalky",
      "Frond Friend",
      "Sapling Star",
      "Bloomington",
      "Fernie",
      "Cactus Jack",
      "Ivy League",
      "Twiggy",
      "Rosie",
      "Dewdrop",
      "Bamboo Jr",
      "Sage Advice",
      "Mossimo",
      "Bud Light",
      "Photosynth",
      "Chloro Phil",
      "Shade Master",
      "Growzilla"
    ]

    SPECIAL_PLANT_ID = "126118"
    SPECIAL_UID = "GP-FC6TL-HSCRR"
    SPECIAL_SECRET_KEY = "gpm_sk__aiMq1UWabBCjp2zHmfurHXvrV6KxBTVzLKrU"
    SPECIAL_PAIRING_CODE = "12345678"

    private_constant :PLANT_NICKNAMES, :SPECIAL_PLANT_ID, :SPECIAL_UID, :SPECIAL_SECRET_KEY,
                     :SPECIAL_PAIRING_CODE

    def initialize(user: Initializer.user, plant: nil, need_water: false)
      @user = user
      @plant = plant
      @need_water = special? ? false : need_water
    end

    def call
      puts "Creating sensor for #{@plant.name}"

      create_sensors!
      create_sensor_readings! if special?

      puts "🛜 Sensor created for #{@plant.display_name}"
    end

    private

    def create_sensors!
      @sensor = Sensor.create!(
        nickname:,
        uid:,
        secret_key:,
        user: @user,
        plant: @plant,
        environment: environment,
        location:,
        moisture_threshold:,
        last_seen_at: rand(1.day).seconds.ago,
        current_data: {
          moisture_level_percent:
        },
        pairing_code:
      )
    end

    def create_sensor_readings!
      SensorReadingsCreator.call(sensor: @sensor)
    end

    def environment
      @environment ||= special? ? :indoor : %i[indoor outdoor].sample
    end

    def location
      special? ? 'bedroom' : "Sensor::#{environment.to_s.upcase}_LOCATIONS".constantize.sample.to_s
    end

    def moisture_threshold
      @plant.min_soil_moisture[environment] || 25
    end

    def moisture_level_percent
      if @need_water
        rand(0..(moisture_threshold - rand(10)))
      else
        rand((moisture_threshold + rand(10..20))..100)
      end
    end

    def nickname
      special? ? 'Jean Célestin' : PLANT_NICKNAMES.sample
    end

    def uid
      return SPECIAL_UID if special?
    end

    def secret_key
      return SPECIAL_SECRET_KEY if special?
    end

    def pairing_code
      return SPECIAL_PAIRING_CODE if special?
    end

    def special?
      @plant.trefle_id.eql?(SPECIAL_PLANT_ID)
    end
  end
end
