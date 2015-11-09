class Player
  include Mongoid::Document
  include Mongoid::Timestamps

  belongs_to :user, :foreign_key => 'owner'
  belongs_to :game_room
  has_and_belongs_to_many :rounds

  field :owner
  field :buy_in
  field :chip_amount
  field :active, type: Boolean
  
  def name
    return self.user.username
  end
  
  
  def self.newPlayer (entering_user, buyInAmount)
    unless buyInOk?(entering_user, buyInAmount)
      raise BuyInExceedsBalanceError, 'buyIn amount exceeds users balance'
    else  
      self.create({user: entering_user, buyIn: buyInAmount, chip_amount: buyInAmount})
    end
  end
    
    
  def self.buyInOk?(user, buyIn) 
    return user.balance >= buyIn
  end
  
  def win(amount)
    chip_amount += amount
    user.balance += amount
    user.save!
  end
  
  def bet(amount)
    unless betOk?(amount)
      chip_amount -= amount
      user.balance -= amount
      user.save!
    else
      raise InvalidBetError, 'bet exceeds users chip_amount'
    end
  end
  
  def betOk?(amount)
    return amount <= chip_amount
  end
  
end


class InvalidBetError < StandardError
end


class BuyInExceedsBalanceError < StandardError
end
