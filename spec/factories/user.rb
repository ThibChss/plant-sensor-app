FactoryBot.define do
  factory :user do
    first_name { 'Jane' }
    last_name { 'Doe' }

    email_address { "#{[first_name, last_name].join('.')}@example.com".downcase }

    password { 'password123' }
    password_confirmation { 'password123' }
  end
end
