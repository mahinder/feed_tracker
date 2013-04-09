class CreateApiKeys < ActiveRecord::Migration
  def change
    create_table :api_keys do |t|
      t.string :access_token
      t.references :user
      t.string :organisation_key

      t.timestamps
    end
  end
end
