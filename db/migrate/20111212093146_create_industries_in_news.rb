class CreateIndustriesInNews < ActiveRecord::Migration
  def self.up
    create_table :industries_in_news do |t|
      t.integer :feed_entry_id
      t.integer :industry_id
    end
  end

  def self.down
    drop_table :industries_in_news
  end
end
