class AddTwitterUserNameToUsers < ActiveRecord::Migration
  def change
    add_column :users, :twitter_user_name, :string
  end
end
