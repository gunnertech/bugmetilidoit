class Task < ActiveRecord::Base
  self.per_page = 100
  
  has_many :assigned_tasks
  has_many :reminders, through: :assigned_tasks
  has_many :users, through: :assigned_tasks
  
  attr_accessible :title, :starts_at
  
  default_scope order{ title.asc }
  
  def to_s
    title
  end
  
  def as_json(options={})
    super(:methods => [:label, :value])
  end
  
  def label
    title
  end
  
  def value
    title
  end
end
