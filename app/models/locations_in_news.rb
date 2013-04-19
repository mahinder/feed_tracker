class LocationsInNews < ActiveRecord::Base
  belongs_to :news
  belongs_to :location
end
