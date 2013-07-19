class AssignedTasksController < InheritedResources::Base
  belongs_to :user, optional: true
  load_and_authorize_resource :assigned_task, through: :user, shallow: true, except: [:index]
  has_scope :filter, type: :hash
  has_scope :by_view
  
  before_filter :authorize_parent
  before_filter :set_default_filter
  before_filter :set_task
  prepend_before_filter :fix_params, only: [:create,:update]
  
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
  
  def view
    params[:view] ||= 'active'
  end
  
  def collection
    return @assigned_tasks if @assigned_tasks
    @assigned_tasks = end_of_association_chain.accessible_by(current_ability).paginate(:page => params[:page])
    @assigned_tasks = @assigned_tasks.by_view(view)
  end
  
  def set_default_filter
    params[:filter] ||= {}
  end
  
  def fix_params
    
    params[:assigned_task] ||= {}
    
    params[:assigned_task][:starts_at_temp] = params[:assigned_task][:starts_at_zone]
    
    if params[:assigned_task]["starts_at_zone(1i)"].present?
      
      params[:assigned_task][:starts_at_zone] = DateTime.new(
                              params[:assigned_task]["starts_at_zone(1i)"].to_i, 
                              params[:assigned_task]["starts_at_zone(2i)"].to_i,
                              params[:assigned_task]["starts_at_zone(3i)"].to_i,
                              params[:assigned_task]["starts_at_zone(4i)"].to_i,
                              params[:assigned_task]["starts_at_zone(5i)"].to_i)
        
      params[:assigned_task].delete("starts_at_zone(1i)")
      params[:assigned_task].delete("starts_at_zone(2i)")
      params[:assigned_task].delete("starts_at_zone(3i)")
      params[:assigned_task].delete("starts_at_zone(4i)")
      params[:assigned_task].delete("starts_at_zone(5i)")
    end
    
  end
  
  def set_task
    @task = Task.find(params[:task_id]) if params[:task_id].present?
  end
end
