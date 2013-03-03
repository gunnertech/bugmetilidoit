class Ability
  include CanCan::Ability

  def initialize(user)
    user ||= User.new # guest user (not logged in)
    if user.has_role? :admin
      can :manage, :all
    else
      can :update, AssignedTask, :user_id => user.id
      can :create, AssignedTask
    end
    
    cannot :create, AssignedTask if user.assigned_tasks.by_view('active').count > 0
  end
end
