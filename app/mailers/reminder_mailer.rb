class ReminderMailer < ActionMailer::Base
  default from: "reminders@bugmetilidoit.com"
  
  def reminder_email(reminder,user)
    @reminder = reminder
    @user = user
    @url  = "http://example.com/login"
    mail(:to => user.email, :subject => "Have you done it yet?")
  end
end
