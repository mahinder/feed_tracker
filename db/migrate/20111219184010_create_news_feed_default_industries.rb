class CreateNewsFeedDefaultIndustries < ActiveRecord::Migration
  def self.up
    create_table :news_feed_default_industries do |t|
      t.integer :news_feed_id
      t.integer :industry_id
    end
  end

  def self.down
    drop_table :news_feed_default_industries
  end
end
