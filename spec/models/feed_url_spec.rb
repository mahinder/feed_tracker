require 'spec_helper'

describe FeedUrl do
  before(:each) do
    @attr = {
      :feed_url  => "http://news.google.co.in/news?pz=1&cf=all&ned=in&hl=en&output=rss"
    }
    @feed_url = FeedUrl.new(@attr) 
  end

  after(:each) do 
    FeedUrl.delete_all
  end 
  
  it "should responde to user " do
    @feed_url.should respond_to(:user) 
  end
  
  it "should responde to feed entries " do
    @feed_url.should respond_to(:feed_entries) 
  end
  it 'feed_url should be accessible' do
    @feed_url.feed_url = "http://news.google.co.in"
    @feed_url.feed_url.should eql("http://news.google.co.in")
  end
  it 'user_id should be accessible' do
    @feed_url.user_id = 1
    @feed_url.user_id.should eql(1)
  end
  
  it "should be invalid when two feed url instance with same url and user id" do
    @feed_url.save
    @feed_url1 = FeedUrl.new(@attr)
    @feed_url1.should_not be_valid
   end
  
  
  
end
