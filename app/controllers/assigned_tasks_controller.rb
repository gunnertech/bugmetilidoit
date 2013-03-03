class AssignedTasksController < InheritedResources::Base
  belongs_to :user, optional: true
  load_and_authorize_resource :assigned_task, through: :user, shallow: true, except: [:index]
  has_scope :filter, type: :hash
  has_scope :by_view
  
  before_filter :authorize_parent
  before_filter :set_default_filter
  
  def create
    create!{ user_assigned_tasks_url(current_user,view: 'active') }
  end
  
  def update
    if request.request_method.to_s != "GET"
      update!{ user_assigned_tasks_url(current_user,view: (params[:view]||"completed")) }
    else
      @assigned_task = current_user.assigned_tasks.find(params[:id])
      @assigned_task.update_attributes(params[:assigned_task])
      redirect_to user_assigned_tasks_url(current_user,view: (params[:view]||"completed"))
    end
  end
  
  protected
  def collection
    return @assigned_tasks if @assigned_tasks
    @assigned_tasks = end_of_association_chain.accessible_by(current_ability).paginate(:page => params[:page])
    @assigned_tasks = @assigned_tasks.by_view(params[:view])
  end
  
  def set_default_filter
    params[:filter] ||= {}
  end
end
