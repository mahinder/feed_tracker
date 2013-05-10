class Location < ActiveRecord::Base
validates :name ,:presence => true ,:uniqueness => true
 attr_accessible :name 
  def self.tag_in_news(news_id, location_name)
    country_code = Geocoder.search(location_name).first.country_code
    location_ids = Thunderbolt::Location.instance.search(country_code)
    location_ids.each do |loc_id|
      LocationsInNews.find_or_create_by_news_id_and_location_id(:news_id => news_id, :location_id => loc_id)
    end
  end
end
