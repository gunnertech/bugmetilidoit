class AddTimeZoneToUsers < ActiveRecord::Migration
  def up
    add_column :users, :time_zone, :string
    User.where{ time_zone == nil }.update_all(time_zone: "Eastern Time (US & Canada)")
  end
  
  def down
    remove_column :users, :time_zone
  end
end
