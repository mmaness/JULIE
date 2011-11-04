class CreateExperiments < ActiveRecord::Migration
  def self.up
    create_table :experiments do |t|
      t.timestamps
      t.string :name, :null => false
      t.string :choice_exp_object, :null => false
      t.timestamps
    end
  end

  def self.down
    drop_table :experiments
  end
end
