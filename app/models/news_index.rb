class NewsIndex < ActiveRecord::Base
  set_table_name "news_indices"
  validates :news_id,:tag,:value , :presence => true
end
