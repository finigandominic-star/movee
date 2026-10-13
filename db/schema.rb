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

ActiveRecord::Schema[8.1].define(version: 2026_10_13_133513) do
  # These are extensions that must be enabled in order to support this database
  enable_extension "pg_catalog.plpgsql"

  create_table "chains", force: :cascade do |t|
    t.boolean "active"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  create_table "involved_parties", force: :cascade do |t|
    t.string "first_name"
    t.string "last_name"
    t.string "email"
    t.string "contact_info"
    t.string "phone"
    t.boolean "seller"
    t.boolean "buyer"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  create_table "properties", force: :cascade do |t|
    t.bigint "user_id", null: false
    t.string "photos"
    t.bigint "involved_party_id"
    t.string "house_number"
    t.string "street"
    t.string "second_line_of_address"
    t.string "city"
    t.string "post_code"
    t.boolean "sold"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["involved_party_id"], name: "index_properties_on_involved_party_id"
    t.index ["user_id"], name: "index_properties_on_user_id"
  end

  create_table "transactions", force: :cascade do |t|
    t.bigint "involved_party_id"
    t.bigint "chain_id", null: false
    t.bigint "property_id", null: false
    t.boolean "completed"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["chain_id"], name: "index_transactions_on_chain_id"
    t.index ["involved_party_id"], name: "index_transactions_on_involved_party_id"
    t.index ["property_id"], name: "index_transactions_on_property_id"
  end

  create_table "users", force: :cascade do |t|
    t.string "email", default: "", null: false
    t.string "encrypted_password", default: "", null: false
    t.string "reset_password_token"
    t.datetime "reset_password_sent_at"
    t.datetime "remember_created_at"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string "user_name"
    t.string "company"
    t.index ["email"], name: "index_users_on_email", unique: true
    t.index ["reset_password_token"], name: "index_users_on_reset_password_token", unique: true
  end

  add_foreign_key "properties", "involved_parties"
  add_foreign_key "properties", "users"
  add_foreign_key "transactions", "chains"
  add_foreign_key "transactions", "involved_parties"
  add_foreign_key "transactions", "properties"
end
