class GameRoom
  include Mongoid::Document
  include Mongoid::Timestamps
  
  has_many :players
  has_many :rounds
  
  field :name, type: String
  field :max_players, type: Int
  field :limit, type: Int
  field :active, type: Boolean
  field :private, type: Boolean
  
  def remove_player(player)
    players.delete(player)
    player.destroy
  end
  
  
  def close_room
    active = false
  end
  
  
  def new_round
    
  end
  
  
  def add_player(user, buy_in)
    unless buy_in_ok?(buy_in)
      players << Player.add_player(user, buy_in)
    else
      raise BuyInExceedsLimitError
    end
  end
  
  
  def buy_in_ok?(buy_in)
    return buy_in <= limit
  end
  
end

class BuyInExceedsLimitError < StandardError
end