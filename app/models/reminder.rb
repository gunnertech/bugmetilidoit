class Reminder < ActiveRecord::Base
  belongs_to :assigned_task
  has_one :user, through: :assigned_task
  attr_accessible :sent_at
end
