FactoryBot.define do
  factory :sensor do
    association :user
    association :plant

    nickname { 'Living room plant' }
    moisture_threshold { 35 }
    last_seen_at { Time.current }

    traits_for_enum :location
    indoor

    current_data do
      {
        moisture_level: 42,
        temperature: 22.5,
        battery_level: 88
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
  end
end
