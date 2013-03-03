class Reminder < ActiveRecord::Base
  belongs_to :assigned_task
  has_one :user, through: :assigned_task
  has_one :task, through: :assigned_task
  
  attr_accessible :sent_at
  
  after_create :send_notices
  
  def send_notices
    ReminderMailer.reminder_email(self,self.user).deliver
    self.assigned_task.remind_at = Time.now + self.assigned_task.reminder_frequency.to_i.minutes
    self.assigned_task.save!
  end
  
end
