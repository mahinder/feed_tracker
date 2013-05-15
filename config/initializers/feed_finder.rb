require 'rubygems'
require 'rufus/scheduler'
require 'feed_enrichment' 
require 'feed_fetcher' 
scheduler = Rufus::Scheduler.start_new

scheduler.cron '25 01 * * 1-7' do  
  FeedFetcher.fetch_feed
end

scheduler.cron '56 01 * * 1-7' do  
 FeedEnrichment.feed_enrichment 
end

scheduler.cron '56 02 * * 1-7' do  
   SendTaggingNews.send_tagging
end
