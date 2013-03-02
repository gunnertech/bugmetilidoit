class AssignedTask < ActiveRecord::Base
  belongs_to :user
  belongs_to :task
  has_many :reminders, dependent: :destroy
  attr_accessible :completed_at, :reminder_frequency
end
