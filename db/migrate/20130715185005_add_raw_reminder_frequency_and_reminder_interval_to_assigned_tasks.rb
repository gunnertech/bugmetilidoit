class AddRawReminderFrequencyAndReminderIntervalToAssignedTasks < ActiveRecord::Migration
  def change
    add_column :assigned_tasks, :raw_reminder_frequency, :integer
    add_column :assigned_tasks, :reminder_interval, :string
  end
end
