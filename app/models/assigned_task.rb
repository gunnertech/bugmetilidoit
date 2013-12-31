class AssignedTask < ActiveRecord::Base
  include IceCube
  
  belongs_to :user
  belongs_to :task
  has_many :reminders, dependent: :destroy
  has_many :assigned_networks, dependent: :destroy
  has_many :networks, through: :assigned_networks
  
  attr_accessible :completed_at, :reminder_frequency, :task_title, :action, :network_ids, :starts_at, :recurring_rule, :starts_at_zone, :starts_at_temp, :reminder_interval, :raw_reminder_frequency, :due_in, :due_in_period, :source, :guid, :task_url
  attr_accessor :task_title, :action, :starts_at_zone, :starts_at_temp, :due_in, :due_in_period
  
  validates :task_title, presence: true
  validates :reminder_frequency, presence: true, numericality: {greater_than: 15}
  validates :network_ids, presence: { message: 'must choose at least one' }
  
  before_validation :set_reminder_frequency
  before_validation :set_task, on: :create
  before_validation :fire_action, if: Proc.new { |assigned_task| assigned_task.action.present? }
  before_create :set_next_reminder_time
  after_save :set_starts_at
  after_create :send_creation_message_to_facebook, if: Proc.new { |assigned_task| assigned_task.user.facebook_access_token.present? }
  before_validation :set_from_simple, if: Proc.new { |assigned_task| assigned_task.due_in.present? }
  
  def set_from_simple
    self.network_ids = [Network.find_by_name("Email").id, Network.find_by_name("SMS").id]
    self.starts_at ||= due_in.to_i.send(due_in_period.downcase.to_sym).from_now
    self.reminder_frequency ||= 1.days / 60
    self.reminder_interval = "Days"
    
  end
  
  
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
  
  def update_url
    "http://#{ENV['HOST']}/users/me/assigned_tasks/#{self.to_param}"
  end
  
  def as_json(options={})
    super(:methods => [:url, :update_url, :zoned_remind_at, :zoned_completed_at], include: {task: {}})
  end
  
  def zoned_remind_at
    # remind_at.in_time_zone(user.time_zone).strftime("%m/%d/%Y %I:%M %p")
    remind_at.in_time_zone(user.time_zone).strftime("%m/%d/%Y")
  end
  
  def zoned_completed_at
    
    # completed_at.in_time_zone(user.time_zone).strftime("%m/%d/%Y %I:%M %p")
    completed_at.present? ? completed_at.in_time_zone(user.time_zone).strftime("%m/%d/%Y") : nil
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
    return_val = @starts_at_zone if starts_at_temp.nil? || (@starts_at_zone.present? && !@starts_at_zone.is_a?(String))
    if return_val.nil? && !new_record? && starts_at.present?
      return starts_at.in_time_zone(user.time_zone)
    elsif return_val.present?
      return return_val
    end
    @starts_at_zone = if user
      zone = ActiveSupport::TimeZone[user.time_zone]
      # raise "#{starts_at_temp.to_s} #{Time.now.strftime('%Z')}"
      offset = zone.tzinfo.current_period.offset.utc_total_offset.to_f / 3600.0
      if offset.abs > 9
        
        if offset < 0
          offset_string = "#{offset.to_i}:00"
        else
          offset_string = "+#{offset.to_i}:00"
        end
      else
        if offset < 0
          offset_string = "-0#{offset.to_i.abs}:00"
        else
          offset_string = "+0#{offset.to_i.abs}:00"
        end
        
      end
      # raise "#{starts_at_temp.to_s.upcase} #{offset_string}"
      # raise Time.now.strftime("%m/%d/%Y %I:%M %p %Z")
      # raise "#{starts_at_temp.to_s.upcase} #{Time.now.strftime('%Z')}"
      # DateTime.strptime("#{starts_at_temp.to_s} #{zone.tzinfo.current_period.offset.utc_total_offset.to_f / 3600.0}","%m/%d/%Y %I:%M %p %Z")#.in_time_zone(user.time_zone)
      # DateTime.strptime("#{starts_at_temp.to_s} #{Time.now.strftime('%Z')}","%m/%d/%Y %I:%M %p %Z")#.in_time_zone(user.time_zone)
      
      DateTime.strptime("#{starts_at_temp.to_s.upcase} #{offset_string}","%m/%d/%Y %I:%M %p %Z") rescue nil
    else
      DateTime.strptime(starts_at_temp.to_s,"%m/%d/%Y %I:%M %p")
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
    (((completed_at||0) - starts_at)/60).to_i
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
  
  def phrase
    if time_to_complete < 60
      "#{time_to_complete} minutes"
    elsif time_to_complete < 1440
      "#{time_to_complete/60} hours"
    else
      "#{time_to_complete/1440} days"
    end
  end
  
  def post_to_twitter
    client = Twitter::Client.new(
      :oauth_token => user.twitter_access_token,
      :oauth_token_secret => user.twitter_access_secret
    )
    
    client.update("Just completed a task (#{self.to_s}) after #{phrase} and #{reminders.count} reminders. #{url}")
  end
  
  def send_creation_message_to_facebook
    if networks.include?(Network.find_or_create_by_name('Facebook'))
      if user.facebook_access_token.present?
        post_to_facebook("I need to #{task.to_s} by #{I18n.l(remind_at)}. Click 'Like' if you think I'm going to finish it on time or comment and tell me why you think I won't.") rescue nil
      end
    end
  end
  
  def post_to_facebook(message=nil,token=nil,url=nil)
    token ||= user.facebook_access_token
    url ||= Rails.application.routes.url_helpers.task_url(task, host: ENV['HOST'])
    message ||= "Just completed a task (#{task.to_s}) after #{phrase} and #{reminders.count} reminders."
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
      unless schedule.nil?
        AssignedTask.create! do |assigned_task|
          assigned_task.user = user
          assigned_task.task = task
          # assigned_task.remind_at = remind_at
          assigned_task.reminder_frequency = reminder_frequency
          assigned_task.recurring_rule = self.read_attribute(:recurring_rule)
          assigned_task.starts_at = schedule.next_occurrence
          assigned_task.networks << networks
        end
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
