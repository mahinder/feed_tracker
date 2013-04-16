class AddLookupSignatureToCompanyAndCompanyTemplate < ActiveRecord::Migration
  def self.up
    add_column :companies, :lookup_signature, :string
#    add_column :company_templates, :lookup_signature, :string
    add_index :companies, :lookup_signature, :name => 'ix_cmp_lookup_sign'
#    add_index :company_templates, :lookup_signature, :name => 'ix_cmp_tmp_lookup_sign'
  end

  def self.down
    remove_column :companies, :lookup_signature
#    remove_column :company_templates, :lookup_signature
  end
end
