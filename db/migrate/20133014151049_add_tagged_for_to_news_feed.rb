class AddTaggedForToNewsFeed < ActiveRecord::Migration
  def change
    add_column :news_feeds, :tagged_for, :text
  end
end
