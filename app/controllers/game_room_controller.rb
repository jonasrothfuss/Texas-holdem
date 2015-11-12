class GameRoomController < ApplicationController
  protect_from_forgery with: :exception

  before_filter :authenticate_user!

  respond_to :json

  def index
    respond_with GameRoom.all
  end

  def create
    respond_with GameRoom.new_room(crud_params), :location => ''
    Pusher.trigger('gamerooms', 'new', crud_params)
  end

  def join
    gameroom = GameRoom.find(params[:id])
    gameroom.add_player(params.require(:user).permit(:_id, :first_name, :last_name, :username, :image_path))

    respond_with gameroom, :location => ''
  end

  def leave
    game_room = GameRoom.find(params[:id])
    respond_with game_room.remove_player(params.require(:user).permit(:_id, :first_name, :last_name, :username, :image_path)), :location => '/home/'
  end

  def players
    gameroom = GameRoom.find(params[:id])
    respond_with gameroom.players
  end

  def message
    head 200, content_type: "text/html"
    Pusher.trigger("gameroom-#{params[:id]}", 'chat', params[:message])
  end

  private
  def crud_params
    params.require(:game_room).permit(:name, :max_players, :min_bet)
  end
end
