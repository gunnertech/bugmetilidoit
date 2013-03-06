class TasksController < InheritedResources::Base
  
  respond_to :json, only: [:index]
  
  protected
  def collection
    return @tasks if @tasks
    @tasks = end_of_association_chain.accessible_by(current_ability).paginate(page: params[:page])
    @tasks = @tasks.where{ title =~ "#{params[:term]}%"}
  end
end
