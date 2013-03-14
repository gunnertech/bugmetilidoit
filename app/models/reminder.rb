class Reminder < ActiveRecord::Base
  belongs_to :assigned_task
  has_one :user, through: :assigned_task
  has_one :task, through: :assigned_task
  
  attr_accessible :sent_at
  
  after_create :send_notices
  
  def send_notices
    ReminderMailer.reminder_email(self,self.user).deliver
    
    if ENV['BLOWERIO_URL']
      @client = Twilio::REST::Client.new "AC9cb7e9f9a83d6e1b6ab9cb907e89ac85", "9d71acdbf9d13fc82ce048557c3866aa"
      @client.account.sms.messages.create(
        :from => '+12038197645',
        :to => self.user.mobile,
        :body => "#{self.task.title}. Did it? Click here: #{Rails.application.routes.url_helpers.complete_assigned_task_url(self.assigned_task, auth_token: self.user.authentication_token, assigned_task: {action: "complete"})}"
      ) rescue nil
      blowerio = RestClient::Resource.new(ENV['BLOWERIO_URL'])
      blowerio['/messages'].post :to => '+13018300451', :message => 'Fuck yeah, SMS!' rescue nil
    end
    
    self.assigned_task.remind_at = Time.now + self.assigned_task.reminder_frequency.to_i.minutes
    self.assigned_task.save!
  end
  
end
