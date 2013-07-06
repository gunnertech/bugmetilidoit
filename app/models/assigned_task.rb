class AssignedTask < ActiveRecord::Base
  include IceCube
  
  belongs_to :user
  belongs_to :task
  has_many :reminders, dependent: :destroy
  has_many :assigned_networks, dependent: :destroy
  has_many :networks, through: :assigned_networks
  
  attr_accessible :completed_at, :reminder_frequency, :task_title, :action, :network_ids, :starts_at, :recurring_rule, :starts_at_zone
  attr_accessor :task_title, :action, :starts_at_zone
  
  validates :task_title, presence: true
  validates :reminder_frequency, presence: true
  validates :network_ids, presence: { message: 'must choose at least one' }
  
  before_validation :set_task, on: :create
  before_validation :fire_action, if: Proc.new { |assigned_task| assigned_task.action.present? }
  before_create :set_next_reminder_time
  after_save :set_starts_at
  
  def schedule
    Schedule.from_hash(recurring_rule)
  end
  
  def recurring_rule
    return if read_attribute(:recurring_rule) == "null"
    return unless read_attribute(:recurring_rule).present?
    RecurringSelect.dirty_hash_to_rule(read_attribute(:recurring_rule))
  end
  
  class << self
    def average_seconds_to_completion(relation=nil)
      relation ||= scoped
      hours, minutes = relation.by_view('completed').group{ id }.select{avg((completed_at - created_at)).as(time)}.first.time.split(/:/).map(&:to_i)
      
      hours*60+minutes
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
    @starts_at_zone ||= if user
      Time.use_zone(user.time_zone) do
        Time.zone.parse(starts_at.to_s)
      end
    else
      Time.zone.parse(starts_at.to_s)
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
    ((completed_at - created_at)/60).to_i
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
  
  protected
  
  def fire_action
    case self.action
    when "abandon"
      self.abandoned_at = Time.now
    when "complete"
      self.completed_at = Time.now
      
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
    self.remind_at = (starts_at||(starts_at_zone.try(:utc)||Time.now) + self.reminder_frequency.to_i.minutes
  end
  
  def set_task
    if task_title.present? && task_title != task.try(:title)
      self.task = Task.find_or_create_by_title(task_title)
    end
  end
  
  def set_starts_at
    self.update_column(:starts_at,starts_at_zone.utc)
  end
  
end
