class CreateJobFunctions < ActiveRecord::Migration
  def self.up
    create_table :job_functions do |t|
      t.string :name
    end
  end

  def self.down
    drop_table :job_functions
  end
end
