class UsersController < InheritedResources::Base
  respond_to :json
  skip_load_and_authorize_resource only: [:oauth, :twitter_oauth]
  skip_before_filter :set_user_id, only: [:oauth, :twitter_oauth]
  
  def oauth
    @oauth = Koala::Facebook::OAuth.new(ENV['FACEBOOK_APP_ID'], ENV['FACEBOOK_APP_SECRET'], oauth_user_url("me"))
    if params[:client_id].present? || params[:code].present?
      facebook_session = @oauth.try(:get_user_info_from_cookies, cookies) || {}
      @user = current_user || User.new
      @user.facebook_access_token = facebook_session["access_token"] || @oauth.get_access_token(params[:code])
      
      if @user.new_record?
        @graph = Koala::Facebook::API.new(@user.facebook_access_token)
        profile = @graph.get_object("me")
        
        if user = (User.find_by_email(profile["email"]) || User.find_by_facebook_id(profile["id"]) || User.find_by_facebook_access_token(@user.facebook_access_token))
          user.facebook_access_token = @user.facebook_access_token
          @user = user
        end
        
        @user.name = profile["name"]
        @user.email = profile["email"]
        @user.password = @user.facebook_access_token[0..100]
        @user.facebook_id = profile["id"]
      elsif !@user.facebook_id
        @graph = Koala::Facebook::API.new(@user.facebook_access_token)
        profile = @graph.get_object("me")
        @user.facebook_id = profile["id"]
      end
      
      @user.save!
      
      sign_in @user if !signed_in?
      
      redirect_to user_path("me"), notice: "Connected to Facebook!"
    else
      redirect_to @oauth.url_for_oauth_code(:permissions => "publish_stream,email,user_likes,publish_actions")
    end
  end
  
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
      params[:id] = current_user.try(:id) if params[:id] == 'me'
      if params[:email].present? && action_name == 'show'
        params[:id] = User.find_by_email(params[:email]).try(:id)
        if params[:id].blank?
          render status: 404, json: {error: "User Does Not Exist"}.to_json and return
        end
      end
    end
  end
  
end