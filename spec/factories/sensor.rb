FactoryBot.define do
  factory :sensor do
    user { nil }
    plant { nil }

    nickname { 'Living room plant' }
    moisture_threshold { 35 }
    last_seen_at { Time.current }

    traits_for_enum :location
    indoor

    current_data do
      {
        moisture_level_percent: 42,
        moisture_level_raw: 2675,
        temperature: 22.5,
        battery_level: 88,
        uptime_seconds: 1000
      }
    end

    trait :with_uid do
      uid { "GP-#{SecureRandom.base58(5)}-#{SecureRandom.base58(5)}".upcase }
    end

    trait :with_secret_key do
      secret_key { "gpm_sk__#{SecureRandom.base58(36)}" }
    end

    trait :with_uid_and_secret_key do
      with_uid
      with_secret_key
    end

    trait :with_user do
      user { create(:user) }
    end

    trait :with_plant do
      plant { create(:plant) }
    end

    trait :with_user_and_plant do
      with_user
      with_plant
    end
  end
end
