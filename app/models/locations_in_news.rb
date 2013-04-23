class LocationsInNews < ActiveRecord::Base
  belongs_to :news
  belongs_to :location
  attr_accessible :news_id , :location_id
end
