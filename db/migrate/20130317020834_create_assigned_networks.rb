class CreateAssignedNetworks < ActiveRecord::Migration
  def change
    create_table :assigned_networks do |t|
      t.belongs_to :network
      t.belongs_to :assigned_task

      t.timestamps
    end
    add_index :assigned_networks, :network_id
    add_index :assigned_networks, :assigned_task_id
  end
end
