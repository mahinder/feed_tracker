class AddVerifiedCompanyIdToCompany < ActiveRecord::Migration
  def self.up
    add_column :companies, :verified_company_id, :integer
    add_index :companies, :verified_company_id, :name => 'ix_comp_verified_comp_id'
  end

  def self.down
    remove_column :companies, :verified_company_id
  end
end
