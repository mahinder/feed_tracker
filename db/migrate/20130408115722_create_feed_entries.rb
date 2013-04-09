class CreateFeedEntries < ActiveRecord::Migration
  def change
    create_table :feed_entries do |t|
      t.string :headline
      t.datetime :published_at
      t.string :url
      t.text :description
      t.boolean :is_enriched , :default => false
      t.references :feed_url
      t.timestamps
    end
  end
end
