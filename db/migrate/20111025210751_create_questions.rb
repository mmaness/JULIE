class CreateQuestions < ActiveRecord::Migration
  def self.up
    create_table :questions do |t|
      t.timestamps
      t.string :question_name, :null => false
      t.string :question_object, :null => false
    end
  end

  def self.down
    drop_table :questions
  end
end
