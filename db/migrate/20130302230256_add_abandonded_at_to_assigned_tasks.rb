class AddAbandondedAtToAssignedTasks < ActiveRecord::Migration
  def change
    add_column :assigned_tasks, :abandoned_at, :datetime
  end
end
