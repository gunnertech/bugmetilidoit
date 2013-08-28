class AddTaskUrlToAssignedTask < ActiveRecord::Migration
  def change
    add_column :assigned_tasks, :task_url, :string
  end
end
