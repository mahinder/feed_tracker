class NewsFeedDefaultLocation < ActiveRecord::Base
  belongs_to :location
  belongs_to :news_feed
  attr_accessible :location_id , :news_feed_id
end
