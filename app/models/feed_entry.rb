class FeedEntry < ActiveRecord::Base
  attr_accessible :description, :headline, :published_at, :url , :is_enriched ,:feed_url_id
  belongs_to :feed_url
 scope :pending_enrichment, :conditions => {:is_enriched => false}
end
