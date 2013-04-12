class FeedEntry < ActiveRecord::Base
  attr_accessible :description, :headline, :published_at, :url , :is_enriched ,:feed_url_id , :calais_data
  belongs_to :feed_url
  has_many :people_in_news, :dependent => :destroy, :class_name => 'PeopleInNews'
  has_many :companies_in_news, :dependent => :destroy, :class_name => 'CompaniesInNews'
  has_many :companies, :through => :companies_in_news
  has_many :people, :through => :people_in_news
  validates :headline, :feed_url_id , :presence => true 
  has_many :industries_in_news, :dependent => :destroy, :class_name => 'IndustriesInNews'
  has_many :industries, :through => :industries_in_news
  scope :pending_enrichment, :conditions => {:is_enriched => false}
end
