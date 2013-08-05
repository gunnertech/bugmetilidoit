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
    full_url = Rails.application.routes.url_helpers.complete_assigned_task_url(assigned_task, auth_token: user.authentication_token, assigned_task: {action: "complete"}, host: ENV['HOST'])
    begin
      u = bitly.shorten(full_url)
    rescue
      Rails.logger.warn("^^^^BAD URL: #{full_url}")
      return true
    end
    
    body = "Stop being lazy and #{task.title}!"[0..159]
    
    ReminderMailer.reminder_email(self,user).deliver if networks.include?(Network.find_or_create_by_name('Email'))
    
    if networks.include?(Network.find_or_create_by_name('SMS'))
      client = Twilio::REST::Client.new ENV['TWILIO_ACCOUNT_SID'], ENV['TWILIO_AUTH_TOKEN']
      to = Rails.env.production? ? "+1#{user.mobile}" : "+1#{ENV['DUMMY_NUMBER']}"
      number = ENV['TWILIO_NUMBERS'].split(",").sample
      begin
        client.account.sms.messages.create(
          :from => "+1#{number}",
          :to => to,
          :body => "#{body} Did it? Click here: #{full_url} - Not you? reply 'STOP'"
        )
      rescue
        Rails.logger.warn("^^^^BAD COMBO: from: #{number} to: #{to}")
      end
    end
    
    if networks.include?(Network.find_or_create_by_name('Twitter'))
      body = "@#{user.twitter_user_name} #{body} #{assigned_task.url}"[0..139]
      Twitter.update(body) unless user.twitter_user_name.blank?
    end
    
    if networks.include?(Network.find_or_create_by_name('Facebook'))
      if assigned_task.user.facebook_access_token.present?
        assigned_task.post_to_facebook("I was supposed to #{task.to_s} by now, but I haven't cause I'm lazy. #{assigned_task.url}") rescue nil
      end
    end
    
    self.assigned_task.remind_at = assigned_task.remind_at + assigned_task.reminder_frequency.to_i.minutes
    self.assigned_task.save!
  end
  
end
