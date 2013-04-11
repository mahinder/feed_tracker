require 'rubygems'
require 'feedzirra'
class FeedFetcher
  
  def fetch_feed
    FeedUrl.all.each do |feed_url_obj|
      feed = Feedzirra::Feed.fetch_and_parse(feed_url_obj.feed_url)
      feed.entries.each do |entry|
        title = entry.title
        published_at = entry.published.localtime
        feed_entry = FeedEntry.new(
          :headline=>title,
          :published_at=>published_at,
          :url=> entry.url,
          :feed_url_id => feed_url_obj.id,
          :description => (entry.content || entry.summary) )
        feed_entry.save
      end
    end 
  end
end
