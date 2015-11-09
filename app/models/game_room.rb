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

  def add_player(user)
    check = Player.where(game_room: id, owner: user, active: true)

    if(check.count == 0)
      player = Player.new_player(user, 5000, id)
      Pusher.trigger("gameroom-#{id}", 'newplayer', player)
    end

    return Player.where(game_room: id, active: true)
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