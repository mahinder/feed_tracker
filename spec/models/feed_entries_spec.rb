require 'spec_helper'

describe FeedEntry do
  
  before :each do
    @attr = {
      :headline => "news",
      :feed_url_id => 1,
      :description => "dddddd",
      :is_enriched => false
    }
    @feed_entry = FeedEntry.new(@attr) 
  end 
  
  it "should responde to feed url " do
    @feed_entry.should respond_to(:feed_url) 
  end
  
   it "should respond to people in news "  do
     @feed_entry.should respond_to(:people_in_news) 
   end
   
   it "should respond to companies_in_news "  do
     @feed_entry.should respond_to(:companies_in_news) 
   end

   it "should respond to companies "  do
     @feed_entry.should respond_to(:companies) 
   end

   it "should respond to people "  do
     @feed_entry.should respond_to(:people) 
   end 

   it "should respond to industries in news "  do
     @feed_entry.should respond_to(:industries_in_news) 
   end
   
   it "should respond to :industries "  do
     @feed_entry.should respond_to(:industries) 
   end
   
  
   it "should not valid at create new instance without  headline" do
     feed_entry_without_heading = @feed_entry = FeedEntry.new(@attr.merge(:headline => ""))
     feed_entry_without_heading.should_not be_valid  
   end
  
   it "should not valid at create new instance without  feed url" do
     feed_entry_without_heading = @feed_entry = FeedEntry.new(@attr.merge(:feed_url_id => ""))
     feed_entry_without_heading.should_not be_valid  
   end
   
  it "scope should work" do
    feed_entry = FeedEntry.create!(@attr)
    FeedEntry.pending_enrichment.should include(feed_entry) 
    
   
  end
  
  
   
end
