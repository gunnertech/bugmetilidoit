class AddStartsAtToAssignedTask < ActiveRecord::Migration
  def change
    add_column :assigned_tasks, :starts_at, :datetime
    
    AssignedTask.all.each { |at| at.update_column(:starts_at, at.created_at) }
  end
end
