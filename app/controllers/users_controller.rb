class UsersController < InheritedResources::Base
  skip_load_and_authorize_resource only: [:twitter_oauth]
  skip_before_filter :set_user_id, only: [:twitter_oauth]
  
  def twitter_oauth
    @consumer = OAuth::Consumer.new(ENV['TWITTER_CONSUMER_KEY'], ENV['TWITTER_CONSUMER_SECRET'],
    { :site => "https://api.twitter.com",
      :request_token_path => '/oauth/request_token',
      :access_token_path => '/oauth/access_token',
      :authorize_path => '/oauth/authorize',
      :scheme => :header
    })
    
    if params[:oauth_verifier].present? && params[:oauth_token].present?
      token = @consumer.get_access_token(session[:request_token],oauth_verifier: params[:oauth_verifier])
      @user = current_user || User.new
      @user.twitter_access_token = token.token
      @user.twitter_access_secret = token.secret
      
      if @user.new_record?
        client = Twitter::Client.new(
          :oauth_token => @user.twitter_access_token,
          :oauth_token_secret => @user.twitter_access_secret
        )
      
        if user = User.where{ (twitter_id == my{client.user[:id]}) | (twitter_access_token == my{@user.twitter_access_token}) }.first
          @user = user
          @user.twitter_access_token = token.token
          @user.twitter_access_secret = token.secret
        end
      
        @user.twitter_id = client.user[:id]
        @user.name = client.user[:screen_name]
        @user.twitter_user_name = client.user[:screen_name]
        @user.password = @user.twitter_access_token
        @user.email = "#{@user.name}@fake-from-twitter.com"
      end
      
      @user.save!
      
      sign_in @user if !signed_in?
      
      redirect_to user_path("me"), notice: "Connected to Twitter!"
    else
      @request_token = @consumer.get_request_token(:oauth_callback => "http://#{ENV['HOST']}/users/me/twitter_oauth")
      session[:request_token] = @request_token
      redirect_to @request_token.authorize_url
    end
  end
  
  protected
  def collection
    return @users if @users
    @users = end_of_association_chain.accessible_by(current_ability).paginate(:page => params[:page])
  end
  
  def set_user_id
    if !devise_controller?
      redirect_to new_user_session_path and return false if !signed_in? && params[:user_id] == 'me'
      params[:id] = current_user.id if params[:id] == 'me'
    end
  end
  
end