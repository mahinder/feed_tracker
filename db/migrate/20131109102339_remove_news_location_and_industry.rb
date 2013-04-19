class RemoveNewsLocationAndIndustry < ActiveRecord::Migration
  def self.up
    remove_column(:news, :location,:industry_id)
  end

  def self.down
    add_column :news,:location, :string
    add_column :news,:industry_id, :integer
  end
end
