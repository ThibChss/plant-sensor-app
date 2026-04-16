FactoryBot.define do
  factory :user do
    first_name { Faker::Name.first_name }
    last_name { Faker::Name.last_name }

    email_address { Faker::Internet.email(name: "#{first_name} #{last_name}") }

    password { 'password123' }
    password_confirmation { 'password123' }
  end
end
