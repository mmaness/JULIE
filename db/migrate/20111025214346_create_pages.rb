class CreatePages < ActiveRecord::Migration
  def self.up
    create_table :pages do |t|
      t.integer :sequence_id, :null => false
      t.timestamps
      t.string :name, :null => false
      t.string :text
    end
  end

  def self.down
    drop_table :pages
  end
end
