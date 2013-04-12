require_relative '../spec_helper'

describe FeedEnrichment do
  
  before :each do
    @attr_feed_entry = {
      :headline => "news",
      :feed_url_id => 1,
      :description => "dddddd",
      :is_enriched => true
    }
    @feed_entry = FeedEntry.new(@attr_feed_entry) 
  end 
  
  after :each do
    FeedEntry.delete_all
  end
  
  describe 'feed_enrichment method' do
    it "should have a fetch_feed method" do
      methods = FeedEnrichment.instance_methods
      methods.should include(:feed_enrichment)
    end
    
    it "should return empty array when feed entries are not in data base" do
      FeedEntry.delete_all
      response = FeedEnrichment.new.feed_enrichment
      response.should be_empty
    end
    
    it "should return empty array when all feed entries are available with is_enrichment =  true" do
      response = FeedEnrichment.new.feed_enrichment
      response.should be_empty
    end
    
    it "should return array with values when feed entries are available with is_enrichment =  false" do
      @feed_entry = FeedEntry.create(@attr_feed_entry.merge(:is_enriched => false))
      response = FeedEnrichment.new.feed_enrichment
      response.should_not be_empty
    end
  end
 
end
