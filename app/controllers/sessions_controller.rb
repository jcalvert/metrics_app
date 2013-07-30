require 'open-uri'
class SessionsController < ApplicationController

  def new
    redirect_to '/auth/github'
  end

  def create
    auth = request.env["omniauth.auth"]
    user = User.where(:provider => auth['provider'], 
                      :uid => auth['uid'].to_s).first || User.create_with_omniauth(auth)
    org_url=auth['extra']['raw_info']['organizations_url']
    orgs=JSON.parse(open(org_url).read)
    has_org = orgs.detect{|org_hash| org_hash["login"] == GITHUB_ORG}
    if has_org
      session[:user_id] = user.id
      user.add_role :admin if User.count == 1 # make the first user an admin
      if user.email.blank?
        redirect_to edit_user_path(user), :alert => "Please enter your email address."
      else
        redirect_to root_url, :notice => 'Signed in!'
      end
    else
      redirect_to root_url, :alert => "You must be part of the #{GITHUB_ORG} Github organization to access."
    end
  end

  def destroy
    reset_session
    redirect_to root_url, :notice => 'Signed out!'
  end

  def failure
    redirect_to root_url, :alert => "Authentication error: #{params[:message].humanize}"
  end

end
