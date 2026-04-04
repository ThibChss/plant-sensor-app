# This file is auto-generated from the current state of the database. Instead
# of editing this file, please use the migrations feature of Active Record to
# incrementally modify your database, and then regenerate this schema definition.
#
# This file is the source Rails uses to define your schema when running `bin/rails
# db:schema:load`. When creating a new database, `bin/rails db:schema:load` tends to
# be faster and is potentially less error prone than running all of your
# migrations from scratch. Old migrations may fail to apply correctly if those
# migrations use external dependencies or application code.
#
# It's strongly recommended that you check this file into your version control system.

ActiveRecord::Schema[8.1].define(version: 2026_04_03_173646) do
  # These are extensions that must be enabled in order to support this database
  enable_extension "pg_catalog.plpgsql"
  enable_extension "pgcrypto"

  # Custom types defined in this database.
  # Note that some types may not work with other database engines. Be careful if changing database.
  create_enum "sensor_location", ["indoor", "outdoor"]

  create_table "plants", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.datetime "created_at", null: false
    t.jsonb "growth_data", default: {"light" => nil, "sowing" => nil, "spread" => {}, "ph_maximum" => nil, "ph_minimum" => nil, "row_spacing" => {}, "bloom_months" => [], "fruit_months" => [], "soil_texture" => nil, "growth_months" => [], "soil_salinity" => nil, "days_to_harvest" => nil, "soil_nutriments" => nil, "max_soil_moisture" => {"indoor" => nil, "outdoor" => nil}, "min_soil_moisture" => {"indoor" => nil, "outdoor" => nil}, "minimum_root_depth" => {}, "atmospheric_humidity" => nil, "maximum_precipitation" => {}, "minimum_precipitation" => {}}, comment: "Additional growth data"
    t.integer "ideal_humidity", comment: "Ideal humidity on a scale of 1 to 10, 1 being very dry, 10 being very humid"
    t.string "image_url"
    t.float "max_temp", comment: "Maximum temperature in Celsius"
    t.float "min_temp", comment: "Minimum temperature in Celsius"
    t.string "name"
    t.string "scientific_name"
    t.jsonb "translated_name", default: {"en" => [], "fr" => []}
    t.string "trefle_id"
    t.datetime "updated_at", null: false
    t.index ["trefle_id"], name: "index_plants_on_trefle_id", unique: true
  end

  create_table "sensors", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.datetime "created_at", null: false
    t.jsonb "current_data", default: {"temperature" => nil, "battery_level" => nil, "moisture_level" => nil}
    t.datetime "last_seen_at"
    t.enum "location", default: "indoor", null: false, enum_type: "sensor_location"
    t.integer "moisture_threshold"
    t.string "nickname"
    t.uuid "plant_id"
    t.string "secret_key", null: false
    t.string "uid", null: false
    t.datetime "updated_at", null: false
    t.uuid "user_id"
    t.index ["current_data"], name: "index_sensors_on_current_data", using: :gin
    t.index ["plant_id"], name: "index_sensors_on_plant_id"
    t.index ["secret_key"], name: "index_sensors_on_secret_key", unique: true
    t.index ["uid"], name: "index_sensors_on_uid", unique: true
    t.index ["user_id"], name: "index_sensors_on_user_id"
  end

  create_table "sessions", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.datetime "created_at", null: false
    t.string "ip_address"
    t.datetime "updated_at", null: false
    t.string "user_agent"
    t.uuid "user_id", null: false
    t.index ["user_id"], name: "index_sessions_on_user_id"
  end

  create_table "solid_cache_entries", force: :cascade do |t|
    t.integer "byte_size", null: false
    t.datetime "created_at", null: false
    t.binary "key", null: false
    t.bigint "key_hash", null: false
    t.binary "value", null: false
    t.index ["byte_size"], name: "index_solid_cache_entries_on_byte_size"
    t.index ["key_hash", "byte_size"], name: "index_solid_cache_entries_on_key_hash_and_byte_size"
    t.index ["key_hash"], name: "index_solid_cache_entries_on_key_hash", unique: true
  end

  create_table "users", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.datetime "created_at", null: false
    t.string "email_address", null: false
    t.string "first_name", null: false
    t.string "last_name", null: false
    t.string "password_digest", null: false
    t.datetime "updated_at", null: false
    t.index ["email_address"], name: "index_users_on_email_address", unique: true
  end

  add_foreign_key "sensors", "plants"
  add_foreign_key "sensors", "users"
  add_foreign_key "sessions", "users"
end
