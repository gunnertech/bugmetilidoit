class AddRecurringRuleToAssignedTasks < ActiveRecord::Migration
  def change
    add_column :assigned_tasks, :recurring_rule, :text
  end
end
