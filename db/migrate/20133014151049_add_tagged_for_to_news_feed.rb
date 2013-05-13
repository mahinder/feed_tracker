class AddTaggedForToNewsFeed < ActiveRecord::Migration
  def change
    add_column :news_feeds, :tagged_for, :text
    add_column :news_feeds, :scope,:string  
  end
end
