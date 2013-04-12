require_relative '../spec_helper'

describe FeedEnrichment do
  
   
  describe 'feed_enrichment method' do
    it "should have a fetch_feed method" do
      methods = FeedEnrichment.instance_methods
      methods.should include(:feed_enrichment)
    end
#    it "should create feed entry when urls exists" do
#      FeedEntry.delete_all
#      FeedFetcher.new.fetch_feed
#      count = FeedEntry.all.count
#      count.should be > 1
#    end
#    it "should not create feed entry when urls not exists" do
#      FeedUrl.delete_all
#      FeedEntry.delete_all
#      FeedFetcher.new.fetch_feed
#      count = FeedEntry.all.count
#      count.should eql(0)
#    end
    
    
  end
  
  
  
  
end
