class AssignedNetwork < ActiveRecord::Base
  belongs_to :network
  belongs_to :assigned_task
  
  attr_accessible :network_id, :network
end
