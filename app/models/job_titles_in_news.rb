class JobTitlesInNews < ActiveRecord::Base
  belongs_to :news
  belongs_to :job_title
  attr_accessible :news_id , :job_title_id
end
