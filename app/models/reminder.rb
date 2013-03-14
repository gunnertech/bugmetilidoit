class Reminder < ActiveRecord::Base
  belongs_to :assigned_task
  has_one :user, through: :assigned_task
  has_one :task, through: :assigned_task
  
  attr_accessible :sent_at
  
  after_create :send_notices
  
  def send_notices
    ReminderMailer.reminder_email(self,self.user).deliver
    
    if ENV['BLOWERIO_URL']
      blowerio = RestClient::Resource.new(ENV['BLOWERIO_URL'])
      blowerio['/messages'].post :to => '+3018300451', :message => 'Fuck yeah, SMS!'
    end
    
    self.assigned_task.remind_at = Time.now + self.assigned_task.reminder_frequency.to_i.minutes
    self.assigned_task.save!
  end
  
end
