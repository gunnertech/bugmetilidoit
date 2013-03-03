class AddTitleIndexToTask < ActiveRecord::Migration
  def change
    add_index :tasks, :title
  end
end
