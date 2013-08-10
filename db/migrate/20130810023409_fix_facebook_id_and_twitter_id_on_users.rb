class FixFacebookIdAndTwitterIdOnUsers < ActiveRecord::Migration
  def up
    change_column :users, :facebook_id, :integer, limit: 8
    change_column :users, :twitter_id, :integer, limit: 8
  end

  def down
  end
end
