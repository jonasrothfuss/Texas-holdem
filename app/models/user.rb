class User
  include Mongoid::Document
  include Mongoid::Paperclip
  include Mongoid::Timestamps

  validates :first_name, :last_name, :username, presence: true
  validates_confirmation_of :password
  validates :email, :email => true

  field :balance,             type: Integer, default: 5000

  has_mongoid_attached_file  :image
  do_not_validate_attachment_file_type :image

  # Include default devise modules. Others available are:
  # :lockable, :timeoutable, :confirmable, :omniauthable,
  devise :database_authenticatable, :registerable,
         :recoverable, :rememberable, :trackable, :validatable
        

  ## Database authenticatable
  field :first_name,         type: String, default: ""
  field :last_name,          type: String, default: ""
  field :username,           type: String, default: ""
  field :email,              type: String, default: ""
  field :encrypted_password, type: String, default: ""

  ## Recoverable
  field :reset_password_token,   type: String
  field :reset_password_sent_at, type: Time

  ## Rememberable
  field :remember_created_at, type: Time

  ## Trackable
  field :sign_in_count,      type: Integer, default: 0
  field :current_sign_in_at, type: Time
  field :last_sign_in_at,    type: Time
  field :current_sign_in_ip, type: String
  field :last_sign_in_ip,    type: String

  ## Confirmable
  field :confirmation_token,   type: String
  field :confirmed_at,         type: Time
  field :confirmation_sent_at, type: Time
  field :unconfirmed_email,    type: String # Only if using reconfirmable

  ## Lockable
  #field :failed_attempts, type: Integer, default: 0 # Only if lock strategy is :failed_attempts
  #field :unlock_token,    type: String # Only if unlock strategy is :email or :both
  #field :locked_at,       type: Time
end
