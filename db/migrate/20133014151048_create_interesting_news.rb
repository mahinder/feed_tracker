class CreateInterestingNews < ActiveRecord::Migration
  def self.up
    create_table :interesting_news do |t|
      t.integer :user_id
      t.integer :news_id
    end
  end

  def self.down
    drop_table :interesting_news
  end
end
