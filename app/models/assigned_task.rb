class AssignedTask < ActiveRecord::Base
  belongs_to :user
  belongs_to :task
  has_many :reminders, dependent: :destroy
  attr_accessible :completed_at, :reminder_frequency, :task_title, :action
  attr_accessor :task_title, :action
  
  validates :reminder_frequency, presence: true
  
  before_validation :set_task, on: :create
  before_validation :fire_action, if: Proc.new { |assigned_task| assigned_task.action.present? }
  before_create :set_next_reminder_time
  
  class << self
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
      where{ remind_at <= my{Time.now} }
    end
    
    def send_reminders
      logger.warn "<<<<<<<REMINDERS CHECK>>>>>>>>"
      ready_for_delivery.find_in_batches do |group|
        sleep(1)
        group.each { |assigned_task| assigned_task.reminders.create! }
      end
    end
  end
  
  def task_title
    return @task_title if @task_title
    task.nil? ? "" : task.title 
  end
  
  def to_s
    task_title
  end
  
  protected
  
  def fire_action
    case self.action
    when "abandon"
      self.abandoned_at = Time.now
    when "complete"
      self.completed_at = Time.now
    end
  end
  
  def set_next_reminder_time
    self.remind_at = Time.now + self.reminder_frequency.to_i.minutes
  end
  
  def set_task
    if task_title.present? && task_title != task.try(:title)
      self.task = Task.find_or_create_by_title(task_title)
    end
  end
  
end