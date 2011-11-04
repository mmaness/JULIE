class CreateVariables < ActiveRecord::Migration
  def self.up
    create_table :variables do |t|
       t.timestamps
       t.integer :respondent_id, :null => false
       t.string :variable_hash, :null => false
    end
  end

  def self.down
    drop_table :variables
  end
end
