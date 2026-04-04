Seed::Initializer.start(from_json: ENV.fetch("FROM_JSON", "true"), env: ENV.fetch("RAILS_ENV", "development"))

return unless Rails.env.development?

puts "Creating user..."
user = User.create!(
  first_name: "Thibault",
  last_name: "Chassine",
  email_address: "thib@gmail.com",
  password: "password"
)
puts "User created: #{user.full_name}"

puts "Creating sensors..."
plants = Plant.where.not("growth_data->'min_soil_moisture'->>'indoor' IS NOT NULL")

rooms_fr = ["Chambre", "Salle de bain", "Salon", "Cuisine"]

5.times do
  plant = plants.sample

  sensor = Sensor.create!(
    nickname: rooms_fr.sample,
    user:,
    plant:,
    location: :indoor,
    moisture_threshold: plant.min_soil_moisture['indoor'],
    last_seen_at: Time.current,
    current_data: {
      moisture_level: rand(0..100),
      temperature: rand(15..25),
      battery_level: rand(60..100)
    }
  )

  puts "🛜 Sensor created: #{sensor.uid} for #{plant.name}"
end

puts "Done ✅"
