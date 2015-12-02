class AccountController < ApplicationController
  # Prevent CSRF attacks by raising an exception.
  # For APIs, you may want to use :null_session instead.
  respond_to :json

  def picture
    user = User.find(params[:id])
    respond_with user.image
  end
end
