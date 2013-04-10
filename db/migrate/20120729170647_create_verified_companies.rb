class CreateVerifiedCompanies < ActiveRecord::Migration
  def self.up
    create_table :verified_companies do |t|
      t.string :name
      t.string :lookup_signature
      t.integer :company_template_id

      t.timestamps
    end

    add_index :verified_companies, :name, :unique => true
    add_index :verified_companies, :lookup_signature
  end

  def self.down
    drop_table :verified_companies
  end
end
