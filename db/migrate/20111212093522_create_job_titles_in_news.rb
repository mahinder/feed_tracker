class CreateJobTitlesInNews < ActiveRecord::Migration
  def self.up
    create_table :job_titles_in_news do |t|
      t.integer :news_id
      t.integer :job_title_id
    end
  end

  def self.down
    drop_table :job_titles_in_news
  end
end
