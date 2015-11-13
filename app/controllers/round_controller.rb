class RoundController < ApplicationController
  protect_from_forgery with: :exception

  before_filter :authenticate_user!

  respond_to :json

  def hand
    round = Round.find(params[:id])
    respond_with round.access_hand(user_param), :location => ''
  end

  def turn
    round = Round.find(params[:id])
    respond_with round.add_turn(user_param, params[:bet]), :location => ''
    round.move
  rescue StandardError => e
    render_error(e)
  end

  private
  def user_param
    params.require(:user).permit(:_id, :first_name, :last_name, :username, :image_path)
  end

  def render_error(error)
    respond_with error, :status => error.status, :location => ''
  end
end
