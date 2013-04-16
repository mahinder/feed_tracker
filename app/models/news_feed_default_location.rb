class NewsFeedDefaultLocation < ActiveRecord::Base
  belongs_to :location
  belongs_to :news_feed
end
