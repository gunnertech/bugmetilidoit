class CreateAssignedTasks < ActiveRecord::Migration
  def change
    create_table :assigned_tasks do |t|
      t.belongs_to :user
      t.belongs_to :task
      t.integer :reminder_frequency
      t.datetime :completed_at
      t.datetime :remind_at

      t.timestamps
    end
    add_index :assigned_tasks, :user_id
    add_index :assigned_tasks, :task_id
  end
end
