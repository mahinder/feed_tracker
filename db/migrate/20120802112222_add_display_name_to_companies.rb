class AddDisplayNameToCompanies < ActiveRecord::Migration
  def self.up
    add_column :companies, :display_name, :string
  end

  def self.down
    remove_column :companies, :display_name
  end
end
