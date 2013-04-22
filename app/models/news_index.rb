class NewsIndex < ActiveRecord::Base
  set_table_name "news_indices"
  validates_presence_of :news_id,:tag,:value
end
