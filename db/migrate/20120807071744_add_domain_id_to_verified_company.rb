class AddDomainIdToVerifiedCompany < ActiveRecord::Migration
  def self.up
    add_column :verified_companies, :domain_id, :integer
    add_index :verified_companies, :domain_id
  end

  def self.down
    remove_column :verified_companies, :domain_id
  end
end
