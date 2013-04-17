class CreatePeopleInNews < ActiveRecord::Migration
  def self.up
    create_table :people_in_news do |t|
      t.integer :news_id
      t.integer :person_id
    end
 end

  def self.down
    drop_table :people_in_news
  end
end
