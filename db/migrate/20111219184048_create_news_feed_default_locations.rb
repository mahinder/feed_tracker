class CreateNewsFeedDefaultLocations < ActiveRecord::Migration
  def self.up
    create_table :news_feed_default_locations do |t|
      t.integer :news_feed_id
      t.integer :location_id
    end
  end

  def self.down
    drop_table :news_feed_default_locations
  end
end
