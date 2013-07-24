class AssignedTask < ActiveRecord::Base
  include IceCube
  
  belongs_to :user
  belongs_to :task
  has_many :reminders, dependent: :destroy
  has_many :assigned_networks, dependent: :destroy
  has_many :networks, through: :assigned_networks
  
  attr_accessible :completed_at, :reminder_frequency, :task_title, :action, :network_ids, :starts_at, :recurring_rule, :starts_at_zone, :starts_at_temp, :reminder_interval, :raw_reminder_frequency
  attr_accessor :task_title, :action, :starts_at_zone, :starts_at_temp
  
  validates :task_title, presence: true
  validates :reminder_frequency, presence: true, numericality: {greater_than: 15}
  validates :network_ids, presence: { message: 'must choose at least one' }
  
  before_validation :set_reminder_frequency
  before_validation :set_task, on: :create
  before_validation :fire_action, if: Proc.new { |assigned_task| assigned_task.action.present? }
  before_create :set_next_reminder_time
  after_save :set_starts_at
  after_create :send_creation_message_to_facebook, if: Proc.new { |assigned_task| assigned_task.user.facebook_access_token.present? }
  
  
  def schedule
    Schedule.from_hash(recurring_rule)
  end
  
  def recurring_rule
    return if read_attribute(:recurring_rule) == "null"
    return unless read_attribute(:recurring_rule).present?
    RecurringSelect.dirty_hash_to_rule(read_attribute(:recurring_rule))
  end
  
  def url
    "http://#{ENV['HOST']}/tasks/#{task.to_param}"
  end
  
  class << self
    def average_seconds_to_completion(relation=nil)
      relation ||= scoped
      hours, minutes = relation.by_view('completed').group{ id }.select{avg((completed_at - created_at)).as(time)}.first.time.split(/:/).map(&:to_i) rescue nil
      
      hours*60+minutes rescue nil
    end
    
    def filter(filter)
      relation = scoped
      filter.each_with_object({}).each do |(filter_type,filter_value),o|
        case filter_type.to_s
        when "status"
          relation = relation.joins{ roles }.where{ roles.id == my{filter_value}}
        end
      end
      relation
    end
    
    def by_view(view)
      relation = scoped
      case view.to_s
      when "active"
        relation = where{ (completed_at == nil) & (abandoned_at == nil) }
      when "completed"
        relation = where{ (completed_at != nil) & (abandoned_at == nil)  }
      when "abandoned"
        relation = where{ abandoned_at != nil }
      end
      relation
    end
    
    def ready_for_delivery
      by_view("active").where{ (starts_at <= Time.now) & (remind_at <= Time.now) }
    end
    
    def send_reminders
      logger.warn "<<<<<<<REMINDERS CHECK>>>>>>>>"
      ready_for_delivery.find_in_batches do |group|
        sleep(1)
        group.each { |assigned_task| assigned_task.reminders.create! }
      end
    end
  end
  
  def starts_at_zone
    return @starts_at_zone if starts_at_temp.nil? || (@starts_at_zone.present? && !@starts_at_zone.is_a?(String))
    @starts_at_zone = if user
      Time.use_zone(user.time_zone) do
        Date.strptime(starts_at_temp.to_s,"%m/%d/%Y %I:%M %p").to_time
      end
    else
      Date.strptime(starts_at_temp.to_s,"%m/%d/%Y %I:%M %p").to_time
    end
  end
  
  # def starts_at_zone=
  #   self.starts_at = starts_at_zone.utc
  # end
  
  def task_title
    return @task_title if @task_title
    task.nil? ? "" : task.title 
  end
  
  def to_s
    task_title
  end
  
  def time_to_complete
    (((completed_at||0) - created_at)/60).to_i
  end
  
  def average_completion_time
    hours, minutes = AssignedTask.by_view('completed').group{ id }.select{avg((completed_at-created_at)).as(time)}.first.time.split(/:/).map(&:to_i)
    hours*60 + minutes
  end
  
  def schedule
    if recurring_rule.present?
      schedule = Schedule.new
      schedule.add_recurrence_rule(recurring_rule)
      schedule
    else
      nil
    end
  end
  
  def post_to_twitter
    client = Twitter::Client.new(
      :oauth_token => user.twitter_access_token,
      :oauth_token_secret => user.twitter_access_secret
    )
    
    client.update("Just completed a task (#{self.to_s}) after #{time_to_complete} minutes and #{reminders.count} reminders. #{url}")
  end
  
  def send_creation_message_to_facebook
    post_to_facebook("Just scheduled a task to do -- #{task.to_s} -- by #{I18n.l(remind_at)}. Click 'Like' if you think I'm going to finish it on time or comment and tell me why you think I won't.")
  end
  
  def post_to_facebook(message=nil,token=nil,url=nil)
    token ||= user.facebook_access_token
    url ||= Rails.application.routes.url_helpers.task_url(task, host: ENV['HOST'])
    message ||= "Just completed a task (#{task.to_s}) after #{time_to_complete} minutes and #{reminders.count} reminders."
    graph = Koala::Facebook::API.new(token)
    graph.put_connections("me", "feed", message: "#{message} #{url}")
  end
  
  protected
  
  def fire_action
    case self.action
    when "abandon"
      self.abandoned_at = Time.now
    when "complete"
      self.completed_at = Time.now
      if user.twitter_access_token
        post_to_twitter rescue nil 
      end
      if user.facebook_access_token
        post_to_facebook rescue nil
      end
      AssignedTask.create! do |assigned_task|
        assigned_task.user = user
        assigned_task.task = task
        # assigned_task.remind_at = remind_at
        assigned_task.reminder_frequency = reminder_frequency
        assigned_task.recurring_rule = self.read_attribute(:recurring_rule)
        assigned_task.starts_at = schedule.next_occurrence unless schedule.nil?
        assigned_task.networks << networks
      end
      
    end
  end
  
  def set_next_reminder_time
    if !starts_at.present? || starts_at.is_a?(String)
      self.remind_at = (starts_at_zone.try(:utc)||Time.now)# + self.reminder_frequency.to_i.minutes
    else
      self.remind_at = (starts_at||starts_at_zone.try(:utc)||Time.now)# + self.reminder_frequency.to_i.minutes
    end
  end
  
  def set_task
    if task_title.present? && task_title != task.try(:title)
      self.task = Task.find_or_create_by_title(task_title)
    end
  end
  
  def set_starts_at
    self.update_column(:starts_at,starts_at_zone.utc) if starts_at_zone.present?
  end
  
  def set_reminder_frequency
    if reminder_interval.present? && raw_reminder_frequency.present?
      self.reminder_frequency ||= raw_reminder_frequency.send(reminder_interval.downcase.to_sym) / 60
    end
  end
  
end
