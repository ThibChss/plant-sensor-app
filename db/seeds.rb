Seed::Initializer.start(from_json: ENV.fetch("FROM_JSON", "true"), env: ENV.fetch("RAILS_ENV", "development"))

if Rails.env.development?
  User.create!(
    first_name: "Thibault",
    last_name: "Chassine",
    email_address: "thib@gmail.com",
    password: "password"
  )
end
