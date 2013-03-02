class CreateReminders < ActiveRecord::Migration
  def change
    create_table :reminders do |t|
      t.belongs_to :assigned_task
      t.datetime :sent_at

      t.timestamps
    end
    add_index :reminders, :assigned_task_id
  end
end
