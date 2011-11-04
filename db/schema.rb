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

ActiveRecord::Schema.define(:version => 20111104150114) do

  create_table "experiments", :force => true do |t|
    t.datetime "created_at"
    t.datetime "updated_at"
    t.string   "name",              :null => false
    t.string   "choice_exp_object", :null => false
  end

  create_table "pages", :force => true do |t|
    t.integer  "sequence_id", :null => false
    t.datetime "created_at"
    t.datetime "updated_at"
    t.string   "name",        :null => false
    t.string   "text"
  end

  create_table "questions", :force => true do |t|
    t.datetime "created_at"
    t.datetime "updated_at"
    t.string   "question_name",   :null => false
    t.string   "question_object", :null => false
    t.integer  "page_id"
  end

  create_table "respondents", :force => true do |t|
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "responses", :force => true do |t|
    t.integer  "respondent_id", :null => false
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "variables", :force => true do |t|
    t.datetime "created_at"
    t.datetime "updated_at"
    t.integer  "respondent_id", :null => false
    t.string   "variable_hash", :null => false
  end

end
