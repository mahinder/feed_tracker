require 'rubygems'
require 'feedzirra'
require 'ruby-debug'
class FeedFetcher
  
  def fetch_feed
    NewsFeed.all.each do |news_feed|
      default_industries = news_feed.news_feed_default_industries
      default_locations = news_feed.news_feed_default_locations
      feed = Feedzirra::Feed.fetch_and_parse(news_feed.feed_url)
      feed.entries.each do |entry|
        title = entry.title
        published_at = entry.published.localtime
        news = News.new(
          :user_id => news_feed.user_id,
          :headline=>title,
          :news_type_id => news_feed.news_type_id,
          :published_at=>published_at,
          :url=> entry.url,
          :description => (entry.content || entry.summary) )
        if news.save
          news.industries_in_news_ids = default_industries.collect{|i| i.industry_id}
          news.locations_in_news_ids = default_locations.collect{|l| l.location_id}
        end
      end if feed
    end 
  end
end
