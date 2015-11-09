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
  
  def addPlayer(user, buy_in)
    unless buyInOk?(buy_in)
      raise BuyInExceedsLimitError
    else
      self.players << Player.newPlayer(user, buy_in)
    end
  end
  
  def buyInOk?(buy_in)
    return buy_in <= self.limit
  end

end


class BuyInExceedsLimitError < StandardError
end