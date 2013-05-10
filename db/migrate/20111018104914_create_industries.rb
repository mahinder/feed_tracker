class CreateIndustries < ActiveRecord::Migration
  def self.up
    create_table :industries do |t|
      t.string :name
    end
    Industry.fill_it_up
    add_index :industries,:name
    
  end

  def self.down
    drop_table :industries
  end
end
