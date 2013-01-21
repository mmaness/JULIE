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

ActiveRecord::Schema.define(:version => 20130119230755) do

  create_table "experiment_responses", :force => true do |t|
    t.integer  "respondent_id", :null => false
    t.datetime "created_at",    :null => false
    t.datetime "updated_at",    :null => false
  end

  create_table "experiment_values", :force => true do |t|
    t.integer  "respondent_id", :null => false
    t.datetime "created_at",    :null => false
    t.datetime "updated_at",    :null => false
  end

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
    t.integer  "respondent_id",     :null => false
    t.datetime "created_at"
    t.datetime "updated_at"
    t.string   "RecentVacation"
    t.string   "International"
    t.string   "Country"
    t.string   "State"
    t.string   "City"
    t.string   "TripReason"
    t.string   "TripLength"
    t.string   "Enjoyment"
    t.string   "TripCost"
    t.string   "SP1"
    t.string   "SP2"
    t.string   "SP3"
    t.string   "SP4"
    t.string   "RespondentID"
    t.string   "Gender"
    t.string   "Age"
    t.string   "Education"
    t.string   "HeadOfHousehold"
    t.string   "Income"
    t.string   "Kids"
    t.string   "Adolescents"
    t.string   "Adults"
    t.string   "Workers"
    t.string   "Zipcode"
    t.string   "HomeType"
    t.string   "Occupation"
    t.string   "Commute"
    t.string   "License"
    t.string   "BuyAnotherVehicle"
    t.string   "BuyNewUsed"
    t.string   "PurchaseTime"
    t.string   "CarsPerHH"
    t.string   "MakeModelPrimary"
    t.string   "BuyReason1"
    t.string   "MakeModelSecond"
    t.string   "BuyReason2"
    t.string   "MakeModelThird"
    t.string   "BuyReason3"
    t.string   "HomeParking"
    t.string   "DriveToWork"
    t.string   "ParkingCost"
    t.string   "VehicleYear"
    t.string   "VehicleMiles"
    t.string   "VehicleHybrid"
    t.string   "VehicleNew"
    t.string   "PurchaseYear"
    t.string   "VehiclePrice"
    t.string   "VehicleMPG"
    t.string   "Enjoyment_Long"
  end

  create_table "variables", :force => true do |t|
    t.datetime "created_at"
    t.datetime "updated_at"
    t.integer  "respondent_id", :null => false
    t.string   "variable_hash", :null => false
  end

end
