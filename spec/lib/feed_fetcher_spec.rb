require_relative '../spec_helper'

describe FeedFetcher do
  
  before(:each) do
    FeedUrl.create(:feed_url => "http://news.google.co.in/news?pz=1&cf=all&ned=in&hl=en&output=rss")
  end

  after(:each) do 
    FeedUrl.delete_all
  end 
 
  describe 'fetch_feed method' do
    it "should have a fetch_feed method" do
      methods = FeedFetcher.instance_methods
      methods.should include(:fetch_feed)
    end
    it "should create feed entry when urls exists" do
      FeedEntry.delete_all
      FeedFetcher.new.fetch_feed
      count = FeedEntry.all.count
      count.should be > 1
    end
    it "should not create feed entry when urls not exists" do
      FeedUrl.delete_all
      FeedEntry.delete_all
      FeedFetcher.new.fetch_feed
      count = FeedEntry.all.count
      count.should eql(0)
    end
    
    
  end
  
  
  
  
end
