class GameRoomController < ApplicationController
  protect_from_forgery with: :exception

  before_filter :authenticate_user!

  respond_to :json

  def index
    respond_with GameRoom.all
  end

  def create
    respond_with GameRoom.create(crud_params), :location => ''
    Pusher.trigger('gamerooms', 'new', crud_params)
  end

  def join
    game_room = GameRoom.find(params[:id])
    game_room.add_player(params.require(:user).permit(:_id, :first_name, :last_name, :username, :image_path))
    game_room[:players] = Player.where(game_room: game_room.id, active: true)

    respond_with game_room, :location => ''
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
