class AddPageIdToQuestions < ActiveRecord::Migration
  def self.up
    add_column :questions, :page_id, :integer
  end

  def self.down
    remove_column :questions, :page_id
  end
end
