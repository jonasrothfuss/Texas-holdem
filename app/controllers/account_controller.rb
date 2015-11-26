class AccountController < ActionController::Base
  # Prevent CSRF attacks by raising an exception.
  # For APIs, you may want to use :null_session instead.
  protect_from_forgery with: :null_session

  respond_to :json

  def picture
    user = User.find(params[:id])
    respond_with user.image
  end
end
