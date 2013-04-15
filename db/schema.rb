# encoding: UTF-8
# This file is auto-generated from the current state of the database. Instead
# of editing this file, please use the migrations feature of Active Record to
# incrementally modify your database, and then regenerate this schema definition.
#
# Note that this schema.rb definition is the authoritative source for your
# database schema. If you need to create the application database on another
# system, you should be using db:schema:load, not running all the migrations
# from scratch. The latter is a flawed and unsustainable approach (the more migrations
# you'll amass, the slower it'll run and the greater likelihood for issues).
#
# It's strongly recommended to check this file into your version control system.

ActiveRecord::Schema.define(:version => 20130408115722) do

  create_table "api_keys", :force => true do |t|
    t.string   "access_token"
    t.integer  "user_id"
    t.string   "organisation_key"
    t.datetime "created_at",       :null => false
    t.datetime "updated_at",       :null => false
  end

  create_table "companies", :force => true do |t|
    t.string   "name"
    t.string   "url",                 :limit => 1024
    t.string   "phone1"
    t.string   "phone2"
    t.string   "fax"
    t.string   "street1"
    t.string   "street2"
    t.string   "city"
    t.string   "state"
    t.string   "zip"
    t.integer  "country_id",                          :default => 1
    t.datetime "created_at",                                         :null => false
    t.datetime "updated_at",                                         :null => false
    t.integer  "verified_company_id"
  end

  add_index "companies", ["verified_company_id"], :name => "ix_comp_verified_comp_id"

  create_table "companies_in_news", :force => true do |t|
    t.integer "feed_entry_id"
    t.integer "company_id"
  end

  create_table "feed_entries", :force => true do |t|
    t.string   "headline"
    t.datetime "published_at"
    t.string   "url"
    t.text     "description"
    t.boolean  "is_enriched",  :default => false
    t.integer  "feed_url_id"
    t.text     "calais_data"
    t.datetime "created_at",                      :null => false
    t.datetime "updated_at",                      :null => false
    t.boolean  "blocked",      :default => false
    t.boolean  "ready",        :default => false
  end

  create_table "feed_urls", :force => true do |t|
    t.integer  "user_id"
    t.string   "feed_url"
    t.datetime "created_at", :null => false
    t.datetime "updated_at", :null => false
  end

  create_table "industries", :force => true do |t|
    t.string "name"
  end

  add_index "industries", ["name"], :name => "index_industries_on_name"

  create_table "industries_in_news", :force => true do |t|
    t.integer "feed_entry_id"
    t.integer "industry_id"
  end

  create_table "people", :force => true do |t|
    t.string   "first_name"
    t.string   "middle_name"
    t.string   "last_name"
    t.string   "email"
    t.integer  "current_company_id"
    t.integer  "last_company_id"
    t.integer  "current_designation_id"
    t.integer  "last_designation_id"
    t.datetime "created_at",             :null => false
    t.datetime "updated_at",             :null => false
  end

  create_table "people_in_news", :force => true do |t|
    t.integer "feed_entry_id"
    t.integer "person_id"
  end

  create_table "rails_admin_histories", :force => true do |t|
    t.text     "message"
    t.string   "username"
    t.integer  "item"
    t.string   "table"
    t.integer  "month",      :limit => 2
    t.integer  "year",       :limit => 8
    t.datetime "created_at",              :null => false
    t.datetime "updated_at",              :null => false
  end

  add_index "rails_admin_histories", ["item", "table", "month", "year"], :name => "index_rails_admin_histories"

  create_table "users", :force => true do |t|
    t.string   "user_name"
    t.boolean  "is_admin"
    t.datetime "created_at",                             :null => false
    t.datetime "updated_at",                             :null => false
    t.string   "email",                  :default => "", :null => false
    t.string   "encrypted_password",     :default => "", :null => false
    t.string   "reset_password_token"
    t.datetime "reset_password_sent_at"
    t.datetime "remember_created_at"
    t.integer  "sign_in_count",          :default => 0
    t.datetime "current_sign_in_at"
    t.datetime "last_sign_in_at"
    t.string   "current_sign_in_ip"
    t.string   "last_sign_in_ip"
  end

  add_index "users", ["email"], :name => "index_users_on_email", :unique => true
  add_index "users", ["reset_password_token"], :name => "index_users_on_reset_password_token", :unique => true

  create_table "verified_companies", :force => true do |t|
    t.string   "name"
    t.string   "lookup_signature"
    t.integer  "company_template_id"
    t.datetime "created_at",          :null => false
    t.datetime "updated_at",          :null => false
  end

  add_index "verified_companies", ["lookup_signature"], :name => "index_verified_companies_on_lookup_signature"
  add_index "verified_companies", ["name"], :name => "index_verified_companies_on_name", :unique => true

end
