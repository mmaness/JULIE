class CreateExperimentValues < ActiveRecord::Migration
  def self.up
    create_table :experiment_values do |t|
      t.integer :respondent_id, :null => false
      t.timestamps
    end
  end

  def self.down
    drop_table :experiment_values
  end
end
