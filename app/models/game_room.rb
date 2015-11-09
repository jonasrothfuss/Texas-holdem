class GameRoom
  include Mongoid::Document
  include Mongoid::Timestamps

  has_many :players
  has_many :rounds

  field :name, type: String
  field :max_players, type: Integer
  field :min_bet, type: Integer
  field :active, type: Boolean
  field :isPrivate, type: Boolean

  def self.add_player(game_id, user)
    game_room = GameRoom.find(game_id)
    check = Player.where(game_room: game_id, owner: user, active: true)
    player = (check.count > 0) ? check : Player.new_player(user, 5000, game_room)
    game_room[:players] = Player.where(game_room: game_id, active: true)

    Pusher.trigger("gameroom-#{game_room[:id]}", 'newplayer', player)

    return game_room
  end

  def remove_player(player)
    self.players.delete(player)
    self.player.destroy
  end

  def close_room
    self.active = false
  end

  def new_round
    rounds << Round.newRound(players)
  end

  def buyInOk?(buy_in)
    return buy_in <= self.limit
  end

end


class BuyInExceedsLimitError < StandardError
end