class Player
  include Mongoid::Document
  include Mongoid::Timestamps

  belongs_to :user, :foreign_key => 'owner'
  belongs_to :game_room
  has_and_belongs_to_many :rounds

  field :owner
  field :chips, type: Integer
  field :small_blind, type: Boolean
  field :big_blind, type: Boolean
  field :active, type: Boolean

  scope :active, -> { where(active: true) }

  def self.new_player (entering_user, buy_in_amount)
    # unless buyInOk?(entering_user, buy_in_amount)
    #   raise BuyInExceedsBalanceError, 'buyIn amount exceeds users balance'
    # else
    # ActionController::Parameters.permit_all_parameters = true
    # params = ActionController::Parameters.new({user: entering_user, buy_in: buy_in_amount, chip_amount: buy_in_amount, game_room: game_room})
    # puts "------------------"
    # puts params.require(:user)
    # puts params.permit(:buy_in, :chip_amount)
    self.create!({owner: entering_user, chips: buy_in_amount, active: true})
    # end
  end

  def self.buyInOk?(user, buyIn)
    return user[:balance] >= buyIn
  end

  def leave
    self.active = false
    save
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
