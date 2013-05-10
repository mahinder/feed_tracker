class CreateNewsTypes < ActiveRecord::Migration
  def self.up
    create_table :news_types do |t|
      t.string :name
    end
   
  end

  def self.down
    drop_table :news_types
  end
end
