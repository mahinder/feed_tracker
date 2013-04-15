class CreateFeedEntries < ActiveRecord::Migration
  def change
    create_table :feed_entries do |t|
      t.string :headline
      t.datetime :published_at
      t.string :url
      t.text :description
      t.boolean :is_enriched , :default => false
      t.references :feed_url
      t.text :calais_data
      t.timestamps
    end
     add_column :feed_entries, :blocked, :boolean, :default=>false
     add_column :feed_entries, :ready, :boolean, :default=>false
  end
  
end
