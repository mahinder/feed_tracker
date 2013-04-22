class CreateNewsIndices < ActiveRecord::Migration
  def self.up
    create_table :news_indices do |t|
      t.integer :news_id
      t.string :tag
      t.string :value
      t.datetime :created_at
    end
    add_index :news_indices, :tag
  end

  def self.down
    drop_table :news_indices
  end
end
