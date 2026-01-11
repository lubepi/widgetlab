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

ActiveRecord::Schema[8.1].define(version: 2026_01_11_220500) do
  # These are extensions that must be enabled in order to support this database
  enable_extension "pg_catalog.plpgsql"

  create_table "dashboard_user_roles", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.bigint "dashboard_id", null: false
    t.integer "role"
    t.datetime "updated_at", null: false
    t.bigint "user_id", null: false
    t.index ["dashboard_id"], name: "index_dashboard_user_roles_on_dashboard_id"
    t.index ["user_id"], name: "index_dashboard_user_roles_on_user_id"
  end

  create_table "dashboard_widgets", force: :cascade do |t|
    t.string "color"
    t.datetime "created_at", null: false
    t.bigint "dashboard_id", null: false
    t.integer "height"
    t.integer "position_x"
    t.integer "position_y"
    t.datetime "updated_at", null: false
    t.bigint "widget_id", null: false
    t.integer "width"
    t.index ["dashboard_id"], name: "index_dashboard_widgets_on_dashboard_id"
    t.index ["widget_id"], name: "index_dashboard_widgets_on_widget_id"
  end

  create_table "dashboards", force: :cascade do |t|
    t.integer "columns"
    t.datetime "created_at", null: false
    t.string "icon"
    t.boolean "is_public"
    t.string "name"
    t.datetime "updated_at", null: false
  end

  create_table "data_source_storages", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.bigint "data_source_id", null: false
    t.datetime "stored_at", null: false
    t.datetime "updated_at", null: false
    t.jsonb "value", default: {}, null: false
    t.index ["data_source_id", "stored_at"], name: "index_data_source_storages_on_data_source_id_and_stored_at"
    t.index ["data_source_id"], name: "index_data_source_storages_on_data_source_id"
    t.index ["stored_at"], name: "index_data_source_storages_on_stored_at"
  end

  create_table "data_source_whitelists", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.bigint "data_source_id", null: false
    t.datetime "updated_at", null: false
    t.bigint "whitelistable_id", null: false
    t.string "whitelistable_type", null: false
    t.index ["data_source_id"], name: "index_data_source_whitelists_on_data_source_id"
    t.index ["whitelistable_type", "whitelistable_id"], name: "index_data_source_whitelists_on_whitelistable"
  end

  create_table "data_sources", force: :cascade do |t|
    t.jsonb "config"
    t.datetime "created_at", null: false
    t.bigint "creator_id", null: false
    t.boolean "is_public"
    t.datetime "last_attempt_at"
    t.text "last_error"
    t.datetime "last_success_at"
    t.string "name"
    t.integer "source_type"
    t.integer "status", default: 0, null: false
    t.datetime "updated_at", null: false
    t.index ["creator_id"], name: "index_data_sources_on_creator_id"
    t.index ["status"], name: "index_data_sources_on_status"
  end

  create_table "user_group_roles", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.integer "role"
    t.datetime "updated_at", null: false
    t.bigint "user_group_id", null: false
    t.bigint "user_id", null: false
    t.index ["user_group_id"], name: "index_user_group_roles_on_user_group_id"
    t.index ["user_id"], name: "index_user_group_roles_on_user_id"
  end

  create_table "user_groups", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.string "name"
    t.datetime "updated_at", null: false
  end

  create_table "user_widget_roles", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.integer "role"
    t.datetime "updated_at", null: false
    t.bigint "user_id", null: false
    t.bigint "widget_id", null: false
    t.index ["user_id"], name: "index_user_widget_roles_on_user_id"
    t.index ["widget_id"], name: "index_user_widget_roles_on_widget_id"
  end

  create_table "users", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.string "email"
    t.string "first_name"
    t.string "last_name"
    t.string "sub"
    t.datetime "updated_at", null: false
    t.index ["email"], name: "index_users_on_email", unique: true
    t.index ["sub"], name: "index_users_on_sub", unique: true
  end

  create_table "widget_data_source_transformers", force: :cascade do |t|
    t.jsonb "config"
    t.datetime "created_at", null: false
    t.bigint "data_source_id", null: false
    t.datetime "updated_at", null: false
    t.bigint "widget_id", null: false
    t.index ["data_source_id"], name: "index_widget_data_source_transformers_on_data_source_id"
    t.index ["widget_id"], name: "index_widget_data_source_transformers_on_widget_id"
  end

  create_table "widgets", force: :cascade do |t|
    t.string "color"
    t.datetime "created_at", null: false
    t.string "description"
    t.boolean "is_public"
    t.string "name"
    t.datetime "updated_at", null: false
    t.integer "widget_type"
  end

  add_foreign_key "dashboard_user_roles", "dashboards"
  add_foreign_key "dashboard_user_roles", "users"
  add_foreign_key "dashboard_widgets", "dashboards"
  add_foreign_key "dashboard_widgets", "widgets"
  add_foreign_key "data_source_storages", "data_sources"
  add_foreign_key "data_source_whitelists", "data_sources"
  add_foreign_key "data_sources", "users", column: "creator_id"
  add_foreign_key "user_group_roles", "user_groups"
  add_foreign_key "user_group_roles", "users"
  add_foreign_key "user_widget_roles", "users"
  add_foreign_key "user_widget_roles", "widgets"
  add_foreign_key "widget_data_source_transformers", "data_sources"
  add_foreign_key "widget_data_source_transformers", "widgets"
end
