class Player
  include Mongoid::Document
  include Mongoid::Timestamps
  
  has_one :user
  belongs_to :game_room
  
  field :buy_in, type: Int
  field :chip_amount, type: Int
  
  def self.new_player (user, buy_in)
    unless buy_in_ok?(user, buy_in)
      self.create({user: user, buy_in: buy_in, chip_amount: buy_in})
    else  
      raise BuyInError, 'buy_in amounth exceeds users balance'
    end
  end
    
    
  def buy_in_ok?(user, buy_in) 
    return user.balance >= buy_in
  end
  
  
  def win(amounth)
    chip_amounth += amounth
    user.balance += amounth
    user.save!
  end
  
  
  def bet(amounth)
    unless bet_ok?(amounth)
      chip_amounth -= amounth
      user.balance -= amounth
      user.save!
    else
      raise InvalidBetError, 'bet exceeds users chip_amounth'
    end
  end
  
  
  def bet_ok?(amounth)
    return amounth <= user.chip_amount
  end
  
end


class InvalidBetError < StandardError
end


class BuyInError < StandardError
end
