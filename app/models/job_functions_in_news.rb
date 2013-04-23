class JobFunctionsInNews < ActiveRecord::Base
  belongs_to :news
  belongs_to :job_function
  attr_accessible :news_id , :job_function_id
end
