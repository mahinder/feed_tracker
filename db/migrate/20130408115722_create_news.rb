class CreateNews < ActiveRecord::Migration
  def change
    create_table :news do |t|
      t.integer :user_id
      t.string :headline
      t.datetime :published_at
      t.string :url
      t.text :description
      t.boolean :is_enriched , :default => false
      t.references :news_feed
      t.string :reason
      t.text :calais_data
      t.timestamps
    end
     add_column :news, :blocked, :boolean, :default=>false
     add_column :news, :ready, :boolean, :default=>false
  end
  
end
