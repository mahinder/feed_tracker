class NewsFeed < ActiveRecord::Base
  belongs_to :user
  belongs_to :news_type
  has_many :news
  validates :feed_url , :uniqueness => {:scope => :user_id}
  attr_accessible :user_id, :news_type_id ,:feed_url ,:tagged_for ,:scope
  has_many :news_feed_default_locations, :dependent=>:destroy
  has_many :locations, :through=>:news_feed_default_locations
  has_many :news_feed_default_industries, :dependent=>:destroy
  has_many :industries, :through=>:news_feed_default_industries
  serialize :companies_id, Array
  scope :today, lambda { where("DATE(created_at) = '#{Date.today.to_s(:db)}'")}
  scope :weekly, lambda { where("DATE(created_at) >= ? AND created_at <= ?",Date.today.beginning_of_week.to_s ,Date.today.end_of_week.to_s  )}
  serialize :tagged_for ,Array
  
  
  
  
  def industry_ids=(ids)
    return if ids[0].blank?
    ids[0].split(',').each do |id|
      self.news_feed_default_industries.build :industry_id=>id
    end
  end
  
  def location_ids=(ids)
    return if ids[0].blank?
    ids[0].split(',').each do |id|
      self.news_feed_default_locations.build :location_id=>id
    end
  end
  
end
