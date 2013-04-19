class AddIndustryAndLocationToNews < ActiveRecord::Migration
  def self.up
    add_column :news, :industry_id, :integer
    add_column :news, :location, :string
    add_index :news,:location
  end

  def self.down
    remove_column :news, :industry_id
    remove_column :news, :location
  end
end
