require 'rubygems'
require 'rufus/scheduler'
require 'feed_enrichment' 
require 'feed_fetcher' 
scheduler = Rufus::Scheduler.start_new

scheduler.cron '38 14 * * 1-7' do  
  FeedFetcher.fetch_feed
end

scheduler.cron '53 14 * * 1-7' do  
 FeedEnrichment.feed_enrichment 
end

