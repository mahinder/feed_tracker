class JobFunctionsInNews < ActiveRecord::Base
  belongs_to :news
  belongs_to :job_function
end
