class Reminder < ActiveRecord::Base
  belongs_to :assigned_task
  has_one :user, through: :assigned_task
  has_one :task, through: :assigned_task
  has_many :networks, through: :assigned_task
  
  attr_accessible :sent_at
  
  after_create :send_notices
  
  def send_notices
    body = "#{self.task.title}. Did it? Click here: #{Rails.application.routes.url_helpers.complete_assigned_task_url(self.assigned_task, auth_token: self.user.authentication_token, assigned_task: {action: "complete"}, host: ENV['HOST'])}"[0..159]
    
    ReminderMailer.reminder_email(self,self.user).deliver if networks.include?(Network.find_or_create_by_name('Email'))
    
    if networks.include?(Network.find_or_create_by_name('SMS'))
      if ENV['BLOWERIO_URL']
        @client = Twilio::REST::Client.new "AC9cb7e9f9a83d6e1b6ab9cb907e89ac85", "9d71acdbf9d13fc82ce048557c3866aa"
        @client.account.sms.messages.create(
          :from => '+12038197645',
          :to => "+1#{self.user.mobile}",
          :body => body
        )
        blowerio = RestClient::Resource.new(ENV['BLOWERIO_URL'])
        blowerio['/messages'].post :to => '+13018300451', :message => 'Fuck yeah, SMS!'
      end
    end
    
    if networks.include?(Network.find_or_create_by_name('Twitter'))
      body = "@#{user.twitter_user_name} #{body}"[0..139]
      Twitter.update(body)
    end
    
    self.assigned_task.remind_at = Time.now + self.assigned_task.reminder_frequency.to_i.minutes
    self.assigned_task.save!
  end
  
end
