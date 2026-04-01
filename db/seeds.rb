Seed::Initializer.start(from_json: true)

User.create!(
  first_name: "Thibault",
  last_name: "Chassine",
  email_address: "thib@gmail.com",
  password: "password"
)
