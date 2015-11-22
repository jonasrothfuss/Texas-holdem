class AccountController < ActionController::Base
  # Prevent CSRF attacks by raising an exception.
  # For APIs, you may want to use :null_session instead.
  
  before_filter :authenticate_user!
  
  def edit
    if valid_password?
      error = error_form_data()
      if error == nil
        user = User.find(current_user)
        update_user_data(user)
        render :json => {
          :succesful => true, 
          :message => "Account details have been saved", 
          :first_name => user.first_name,
          :last_name => user.last_name,
          :email => user.email,
          :username => user.username
        }.to_json
      else
        render :json => {:succesful => false, :message => "Saving new account data was not succesful: " + error}.to_json
      end
    else
      render :json => {:succesful => false, :message => "Invalid Password"}.to_json
    end
  end
  
  def delete
    if valid_password?
      user = User.find(current_user)
      user.delete
      render :json => {:succesful => true, :message => "Account has been deleted"}.to_json
    else
      render :json => {:succesful => false, :message => "Invalid password. Enter the correct password to delete your account"}.to_json
    end
  end
  
  def picture
    user = User.find(current_user)
    puts "--------------------- USER ID ---" + user.id.to_s
    if File.exist?(image_location_jpg(user.id))
      send_file image_location_jpg(user_id), type: 'image/jpg', disposition: 'inline'
    elsif File.exist?(image_location_png(user.id))
      send_file image_location_png(user.id), type: 'image/png', disposition: 'inline'
    else
      send_file default_image_location, type: 'image/png', disposition: 'inline'
    end
  end
  
  def image_location_jpg(user_id)
    return image_location + user_id.to_s + ".jpg"
  end
  
  def image_location_png(user_id)
    return image_location + user_id.to_s + ".png"
  end
  
  def default_image_location
    return image_location + "default_user_image.png"
  end
  
  def image_location
    return "app/assets/images/user/"
  end
  
  
  def update_user_data(user)
    user.first_name = params[:first_name]
    user.last_name = params[:last_name]
    user.email = params[:email]
    user.username = params[:username]
    unless params[:new_password] == "" 
      user.password = params[:new_password] 
    end
    user.save!
  end
  
  def error_form_data
    puts "ERROR FORM DATA"
    if not (params[:first_name].is_a?(String) && params[:first_name].length >= 3)
      return "Invalid first name"
    elsif not (params[:last_name].is_a?(String) && params[:last_name].length >= 3)
      return "Invalid last name"
    elsif not (params[:email].is_a?(String) && params[:email].length >= 5)
      return "Invalid email"
    elsif not (params[:username].is_a?(String) && params[:username].length >= 3)
      return "Invalid username"
    elsif (not params[:new_password] == "") && (not (params[:new_password].is_a?(String) && params[:new_password].length >= 8))
      return "New password needs to have at least 8 digits"
    else
      return nil
    end
  end
  
  def valid_password?
    return User.find(current_user).valid_password?(params[:password])
  end

end
