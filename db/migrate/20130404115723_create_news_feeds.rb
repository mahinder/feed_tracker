class CreateNewsFeeds < ActiveRecord::Migration
  def change
    create_table :news_feeds do |t|
      t.references :user
      t.integer :news_type_id
      t.string :feed_url
      t.timestamps
    end
  end
end
