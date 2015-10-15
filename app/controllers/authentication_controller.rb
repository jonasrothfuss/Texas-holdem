class AuthenticationController < ApplicationController
  
  before_action :confirm_logged_in, :except =>     [:registration, :login, :createuser, :attempt_login, :logout, :valid_email_format?] 

  DEAFAULT_BALANCE = 5000
  
  def index
    if confirm_logged_in
      redirect_to(:controller => 'lobby', :action => 'lobby')
    else
      redirect_to(:action => 'login')
    end
  end
  
  def registration
  end

  def login
  end


  def createuser

    name = params[:name]
    email = params[:email]
    username = params[:username]
    password = params[:password]
    balance = DEAFAULT_BALANCE
    confirmed = true #TODO: Change later to false after adding email validation

    if name == nil
      redirect_to(:action => 'registration')
      flash[:notice] = "Please provide your name in order to register!"
    elsif email == nil || !valid_email_format?(email)
      redirect_to(:action => 'registration')
      flash[:notice] = "Please provide a valid email adress in order to register!"
    elsif username == nil
      redirect_to(:action => 'registration')
      flash[:notice] = "Please provide a username in order to register!"
    elsif not User.where(:username => params[:username]).blank?
      redirect_to(:action => 'registration')
      flash[:notice] = "Username already exists!"
    elsif password == nil || password.to_s.length < 6
      redirect_to(:action => 'registration')
      flash[:notice] = "Unvalid password - Your password muss at least consist of 6 digits!"
    else
      #Data ok --> can be stored in the database
      
      #Create User in the database
      new_user = User.create(:name => name,:email => email, :username => username, :password => password, :balance => balance, :confirmed => confirmed)
      
      # Send registration confirmation message
      # UserMailer.registration_confirmation(new_user).deliver  
      
      redirect_to(:action => 'login')
      
      #TODO: Redirect user to extra page after succesful registration
  
    end 
  end


  def attempt_login
    if params[:username].present? && params[:password].present?
      found_user = User.where(:username => params[:username]).first
      if found_user
        authorized_user = found_user.authenticate(params[:password])
      end
    end

    if authorized_user && authorized_user.confirmed 
      #mark user as logged in
      session[:user_id] = authorized_user.id
      session[:username] = {:value => authorized_user.username, :expires => 1.week.from_now} 

      flash[:notice] = "Login succesful!"
      redirect_to('/lobby')
    elsif authorized_user #user registered but did not confirm his email
      redirect_to(:action => "login")
      flash[:notice] = "Please verify your email by clicking on the link in verification email we sent you."
    else
      redirect_to(:action => "login")
      flash[:notice] = "Invalid username/password combination"
    end
  end


  def logout
     # mark user as logged out
     session[:user_id] = nil
     session[:username] = nil  

     redirect_to(:action => "login")
     flash[:notice] = "You have been succesfuly logged out."
  end

  def confirm_email
    user = User.find_by_confirm_token(params[:id])
    if user_params
      user.email_activate
      redirect_to(:action => "login")
      flash[:notice] = "Your account has now been activated!"
    else
      #TODO: Tell user that account verification was not succesful
    end
  end

  private
  def valid_email_format?(email)
    return email =~ /\A[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\.[A-Za-z]+\z/
  end

end
