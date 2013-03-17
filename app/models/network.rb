class Network < ActiveRecord::Base
  has_many :assigned_networks, dependent: :destroy
  has_many :assigned_tasks, through: :assigned_networks
  
  attr_accessible :name
end
