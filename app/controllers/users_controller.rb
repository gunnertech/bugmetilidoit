class UsersController < InheritedResources::Base
  protected
  def collection
    return @users if @users
    @users = end_of_association_chain.accessible_by(current_ability).paginate(:page => params[:page])
  end
  
end