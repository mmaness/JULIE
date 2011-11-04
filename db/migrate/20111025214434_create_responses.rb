class CreateResponses < ActiveRecord::Migration
  def self.up
    create_table :responses do |t|
      t.integer :respondent_id, :null => false
      t.timestamps
    end
  end

  def self.down
    drop_table :responses
  end
end
