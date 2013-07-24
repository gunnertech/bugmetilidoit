class User < ActiveRecord::Base
  rolify
  # Include default devise modules. Others available are:
  # , :confirmable,
  # :lockable, :timeoutable and :omniauthable
  devise :database_authenticatable, :registerable, :token_authenticatable,
         :recoverable, :rememberable, :trackable, :validatable

  # Setup accessible (or protected) attributes for your model
  attr_accessible :role_ids, :as => :admin
  attr_accessible :name, :email, :password, :password_confirmation, :remember_me, :mobile, :twitter_user_name, :time_zone, :disconnect_from_twitter
  attr_accessor :disconnect_from_twitter
  
  has_many :assigned_tasks, dependent: :destroy
  has_many :tasks, through: :assigned_tasks
  
  before_validation :remove_twitter_token, if: Proc.new{ |user| user.disconnect_from_twitter == "1" }
  before_save :ensure_authentication_token
  before_save :set_default_time_zone
  
  def to_s
    name
  end
  
  
  def remove_twitter_token
    self.twitter_access_token = nil
    self.twitter_access_secret = nil
  end
  
  def set_default_time_zone
    self.time_zone ||= "Eastern Time (US & Canada)"
  end
end
