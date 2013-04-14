class Reminder < ActiveRecord::Base
  belongs_to :assigned_task
  has_one :user, through: :assigned_task
  has_one :task, through: :assigned_task
  has_many :networks, through: :assigned_task
  
  attr_accessible :sent_at
  
  after_create :send_notices
  
  def send_notices
    Bitly.use_api_version_3
    bitly = Bitly.new("gunnertech", "R_b75c09fa28aa15f9e53ccb9245a9acf6")
    
    u = Bitly.client.shorten(Rails.application.routes.url_helpers.complete_assigned_task_url(assigned_task, auth_token: user.authentication_token, assigned_task: {action: "complete"}, host: ENV['HOST']))
    body = "#{task.title}. Did it? Click here: #{u.short_url}"[0..159]
    
    ReminderMailer.reminder_email(self,user).deliver if networks.include?(Network.find_or_create_by_name('Email'))
    
    if networks.include?(Network.find_or_create_by_name('SMS'))
      if ENV['BLOWERIO_URL']
        # @client = Twilio::REST::Client.new "AC9cb7e9f9a83d6e1b6ab9cb907e89ac85", "9d71acdbf9d13fc82ce048557c3866aa"
        # @client.account.sms.messages.create(
        #   :from => '+12038197645',
        #   :to => "+1#{user.mobile}",
        #   :body => body
        # )
        blowerio = RestClient::Resource.new(ENV['BLOWERIO_URL'])
        blowerio['/messages'].post :to => "+1#{user.mobile}", :message => body
      end
    end
    
    if networks.include?(Network.find_or_create_by_name('Twitter'))
      body = "@#{user.twitter_user_name} #{body}"[0..139]
      Twitter.update(body)
    end
    
    self.assigned_task.remind_at = assigned_task.remind_at + assigned_task.reminder_frequency.to_i.minutes
    self.assigned_task.save!
  end
  
end
