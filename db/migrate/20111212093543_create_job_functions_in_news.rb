class CreateJobFunctionsInNews < ActiveRecord::Migration
  def self.up
    create_table :job_functions_in_news do |t|
      t.integer :news_id
      t.integer :job_function_id
    end
  end

  def self.down
    drop_table :job_functions_in_news
  end
end
