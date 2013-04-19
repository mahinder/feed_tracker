class CreateLocationsInNews < ActiveRecord::Migration
  def self.up
    create_table :locations_in_news do |t|
      t.integer :news_id
      t.integer :location_id
    end
  end

  def self.down
    drop_table :locations_in_news
  end
end
