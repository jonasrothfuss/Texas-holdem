class RoundController < ApplicationController
  protect_from_forgery with: :exception

  before_filter :authenticate_user!

  respond_to :json

  def hand
    round = Round.find(params[:id])
    respond_with round.access_hand(params.require(:user).permit(:_id, :first_name, :last_name, :username, :image_path)), :location => ''
  end
end
