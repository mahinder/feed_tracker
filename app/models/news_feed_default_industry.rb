class NewsFeedDefaultIndustry < ActiveRecord::Base
  belongs_to :industry
  belongs_to :news_feed
end
