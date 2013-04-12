class FeedUrl < ActiveRecord::Base
  belongs_to :user
  has_many :feed_entries
  validates :feed_url_id , :uniqueness => {:scope => :user_id}
  attr_accessible :feed_url, :user_id
end
