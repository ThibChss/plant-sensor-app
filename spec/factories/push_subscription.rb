FactoryBot.define do
  factory :push_subscription do
    sequence(:endpoint) { |n| "https://fcm.googleapis.com/fcm/send/example-endpoint-#{n}" }
    p256dh_key { 'BNcRdreALRFXTkOOUHK1EtK2wtaz5Ry4YfYCA_0QTpQtUbVlTLsTjro' }
    auth_key { 'tBHItJI5svbpez7KI4CCXg' }
    user_agent { 'Mozilla/5.0' }
    pwa { false }
    association :user

    trait :pwa do
      pwa { true }
    end
  end
end
