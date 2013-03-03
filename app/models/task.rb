class Task < ActiveRecord::Base
  self.per_page = 100
  
  has_many :assigned_tasks
  
  attr_accessible :title
  
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
