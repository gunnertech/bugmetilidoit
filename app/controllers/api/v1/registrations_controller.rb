class Api::V1::RegistrationsController < ApplicationController
  skip_before_filter :verify_authenticity_token
  skip_load_and_authorize_resource
  respond_to :json
  
  def create

    user = User.new do |u|
      u.email = params[:user][:email]
      u.name = params[:user][:name]
      u.password = params[:user][:password]
      u.password_confirmation = params[:user][:password]
    end

    if user.save
      render :json => user, :status=>201
      return
    else
      warden.custom_failure!
      render :json => user.errors, :status=>422
    end
  end

  def user_params
    params.require(:user).permit(:email, :password)
  end
  
end