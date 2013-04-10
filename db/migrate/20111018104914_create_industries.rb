class CreateIndustries < ActiveRecord::Migration
  def self.up
    create_table :industries do |t|
      t.string :name
    end
    add_index :industries,:name
  end

  def self.down
    drop_table :industries
  end
end
