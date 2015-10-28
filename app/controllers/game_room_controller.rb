class GameRoomController < ApplicationController
  protect_from_forgery with: :exception

  before_filter :authenticate_user!

  respond_to :json

  def index
    respond_with GameRoom.all
  end

  def create
    respond_with GameRoom.create(post_params)
    Pusher.trigger('gamerooms', 'new', post_params)
  end

  private
  def post_params
    params.require(:game_room).permit(:name, :max_players, :min_bet)
  end
end
