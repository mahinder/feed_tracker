class CreatePeople < ActiveRecord::Migration
  def self.up
    create_table :people do |t|
      t.string :first_name
      t.string :middle_name
      t.string :last_name
      t.string :email
      t.integer :current_company_id
      t.integer :last_company_id
      t.integer :current_designation_id
      t.integer :last_designation_id
      t.timestamps
    end
  end

  def self.down
    drop_table :people
  end
end
