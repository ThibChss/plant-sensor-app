FactoryBot.define do
  factory :notification do
    association :user
    type { 'Notifications::SensorConnected' }
    data { {} }
    read_at { nil }

    trait :read do
      read_at { 1.hour.ago }
    end
  end
end
