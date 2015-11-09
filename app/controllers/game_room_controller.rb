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
    respond_with GameRoom.add_player(params[:id], params.require(:user).permit(:_id, :first_name, :last_name, :username, :image_path)), :location => ''
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
