require 'rubygems'
require 'rufus/scheduler'
require 'feed_enrichment' 
require 'feed_fetcher' 
scheduler = Rufus::Scheduler.start_new

scheduler.cron '25 12 * * 1-7' do  
  FeedFetcher.new.fetch_feed
end

scheduler.cron '56 17 * * 1-7' do  
 FeedEnrichment.new.feed_enrichment 
end

