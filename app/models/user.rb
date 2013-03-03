class User < ActiveRecord::Base
  rolify
  # Include default devise modules. Others available are:
  # , :confirmable,
  # :lockable, :timeoutable and :omniauthable
  devise :database_authenticatable, :registerable, :token_authenticatable,
         :recoverable, :rememberable, :trackable, :validatable

  # Setup accessible (or protected) attributes for your model
  attr_accessible :role_ids, :as => :admin
  attr_accessible :name, :email, :password, :password_confirmation, :remember_me
  
  has_many :assigned_tasks, dependent: :destroy
  has_many :tasks, through: :assigned_tasks
  
  before_save :ensure_authentication_token
  
  def to_s
    name
  end
  
end
