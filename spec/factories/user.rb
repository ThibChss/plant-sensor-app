FactoryBot.define do
  factory :user do
    first_name { 'Jane' }
    last_name { 'Doe' }

    email_address { Faker::Internet.unique.email }

    password { 'password123' }
    password_confirmation { 'password123' }
  end
end
