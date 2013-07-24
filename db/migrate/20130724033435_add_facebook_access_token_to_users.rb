class AddFacebookAccessTokenToUsers < ActiveRecord::Migration
  def change
    add_column :users, :facebook_access_token, :string
    add_index :users, :facebook_access_token
  end
end
