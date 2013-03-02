class AssignedTasksController < InheritedResources::Base
  belongs_to :user
  load_and_authorize_resource :assigned_task, through: :user
  
  before_filter :authorize_parent
  
  protected
  def collection
    return @assigned_tasks if @assigned_tasks
    @assigned_tasks = end_of_association_chain.accessible_by(current_ability).paginate(:page => params[:page])
  end
end
