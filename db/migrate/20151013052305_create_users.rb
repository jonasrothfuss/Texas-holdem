class CreateUsers < ActiveRecord::Migration

  def up
    create_table :users do |t|
      t.column "name", :string, :limit => 70
      t.column "email", :string, :limit => 50, :null => false
      t.column "username", :string, :null => false
      t.column "password_digest", :string, :null => false
      t.column "balance", :integer
      t.column "image_path", :string
      t.column "confirmed", :boolean, :null => false
      t.column "confirm_token", :string #token for email verification

      t.timestamps null: false #creates 'created_at' and 'updated_at' columns
    end
  end

  def down
    drop_table :users
  end
end
