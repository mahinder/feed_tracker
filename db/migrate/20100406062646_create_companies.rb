class CreateCompanies < ActiveRecord::Migration
  def self.up
    create_table :companies do |t|
      t.string :name, :limit => 255
      t.string :url, :limit => 1024
      t.string :phone1
      t.string :phone2
      t.string :fax
      t.string :street1
      t.string :street2
      t.string :city
      t.string :state
      t.string :zip
      t.integer :country_id, :default => 1
      t.timestamps
    end
  end

  def self.down
    drop_table :companies
  end
end
