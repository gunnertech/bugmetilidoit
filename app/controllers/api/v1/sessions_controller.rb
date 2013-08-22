class Api::V1::SessionsController < Devise::SessionsController  
  def create  
    respond_to do |format|
      format.html { super }
      format.json {
        warden.authenticate!(scope: resource_name, recall: "#{controller_path}#new")
        render status: 200, json: current_user.to_json(methods: [:authentication_token])
      }
    end
  end
  
  def destroy
    super
  end
end