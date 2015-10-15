class User < ActiveRecord::Base
  #self.table_name = "users"
  #
  # User has following attributes:
  # id
  # name
  # email
  # username
  # password
  # balance
  # image_path
  # confirmed
  # confirm_token
  
  # has_secure_password provides the following:
  # attr_reader :password
  # #password=(unencrypted_password)
  #
  # #authenticate(unencrypted_password) => boolean
  

  has_secure_password

  def confirm_token
    if self.confirm_token.blank?
      self.confirm_token = SecureRandom.urlsafe_base64.to_s
    end
  end

  def email_activate
    self.confirmed = true
    save!(:validate => false)
  end

end
