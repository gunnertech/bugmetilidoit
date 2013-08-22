class AddSourceAndGuidToAssignedTask < ActiveRecord::Migration
  def change
    add_column :assigned_tasks, :source, :string
    add_column :assigned_tasks, :guid, :string
    
    add_index :assigned_tasks, :source
    add_index :assigned_tasks, :guid
  end
end
