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

ActiveRecord::Schema[8.1].define(version: 2026_11_02_000600) do
  # These are extensions that must be enabled in order to support this database
  enable_extension "pg_catalog.plpgsql"

  create_table "accounts", force: :cascade do |t|
    t.string "first_name", default: "", null: false
    t.string "last_name", default: "", null: false
    t.string "email", default: "", null: false
    t.string "encrypted_password", default: "", null: false
    t.string "url"
    t.string "reset_password_token"
    t.datetime "reset_password_sent_at", precision: nil
    t.datetime "remember_created_at", precision: nil
    t.integer "sign_in_count", default: 0, null: false
    t.datetime "current_sign_in_at", precision: nil
    t.datetime "last_sign_in_at", precision: nil
    t.inet "current_sign_in_ip"
    t.inet "last_sign_in_ip"
    t.string "confirmation_token"
    t.datetime "confirmed_at", precision: nil
    t.datetime "confirmation_sent_at", precision: nil
    t.string "unconfirmed_email"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string "image"
    t.string "company"
    t.string "telephone"
    t.boolean "admin", default: false
    t.text "details"
    t.string "cover_image"
    t.index ["email"], name: "index_accounts_on_email", unique: true
    t.index ["reset_password_token"], name: "index_accounts_on_reset_password_token", unique: true
  end

  create_table "agent_messages", force: :cascade do |t|
    t.bigint "account_id", null: false
    t.string "name", limit: 120, null: false
    t.string "email", limit: 254, null: false
    t.text "message", null: false
    t.string "status", limit: 20, default: "new", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["account_id", "created_at"], name: "index_agent_messages_on_account_id_and_created_at"
    t.index ["account_id"], name: "index_agent_messages_on_account_id"
  end

  create_table "enquiries", force: :cascade do |t|
    t.bigint "property_id", null: false
    t.string "name", limit: 120, null: false
    t.string "email", limit: 254, null: false
    t.text "message", null: false
    t.string "status", limit: 20, default: "new", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["property_id", "created_at"], name: "index_enquiries_on_property_id_and_created_at"
    t.index ["property_id"], name: "index_enquiries_on_property_id"
  end

  create_table "posts", force: :cascade do |t|
    t.string "title"
    t.string "url"
    t.string "summary"
    t.text "body"
    t.string "image"
    t.boolean "active", default: true
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  create_table "properties", force: :cascade do |t|
    t.bigint "account_id"
    t.string "name"
    t.string "address"
    t.integer "price"
    t.integer "rooms"
    t.integer "bathrooms"
    t.string "photo"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.integer "parking_spaces", default: 0
    t.text "details"
    t.boolean "for_sale", default: true
    t.datetime "available_date", precision: nil
    t.string "status", default: "available"
    t.index ["account_id"], name: "index_properties_on_account_id"
  end

  add_foreign_key "agent_messages", "accounts"
  add_foreign_key "enquiries", "properties"
end
