class NewsFeedDefaultIndustry < ActiveRecord::Base
  belongs_to :industry
  belongs_to :news_feed
  attr_accessible :industry_id , :news_feed_id
end
