class CreateCompaniesInNews < ActiveRecord::Migration
  def self.up
    create_table :companies_in_news do |t|
      t.integer :feed_entry_id
      t.integer :company_id
    end
    
  end

  def self.down
    drop_table :companies_in_news
  end
end
