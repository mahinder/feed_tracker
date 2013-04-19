class JobTitlesInNews < ActiveRecord::Base
  belongs_to :news
  belongs_to :job_title
end
