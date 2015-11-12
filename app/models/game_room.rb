class GameRoom
  include Mongoid::Document
  include Mongoid::Timestamps

  has_many :players
  has_many :rounds

  field :name, type: String
  field :max_players, type: Integer
  field :min_bet, type: Integer
  field :active, type: Boolean
  field :closed, type: Boolean
  field :isPrivate, type: Boolean

  default_scope -> { where(closed: false) }

  def self.new_room(params)
    self.create(params.merge!(active: false, closed: false))
  end

  def add_player(user)
    check = self.players.where(owner: user)

    if (check.count == 0)
      player = Player.new_player(user, 5000)
      self.players << player
      save
      Pusher.trigger("gameroom-#{id}", 'newplayer', player)
    end

    return self.players
  end

  def remove_player(user)
    player = Player.where(game_room: id, owner: user).first
    player.leave()
    Pusher.trigger("gameroom-#{id}", 'playerleft', player)
  end

  def close_room
    self.active = false
  end

  def start
    active_players = self.players

    if (!self.active && active_players.count >= 2)
      new_round(active_players)
      self.active = true
      save
    end
  end

  def new_round(players)
    round = Round.new_round(players)
    round.start
    self.rounds << round
    save
    Pusher.trigger("gameroom-#{id}", 'newround', round)
  end

  def buyInOk?(buy_in)
    return buy_in <= self.limit
  end

end


class BuyInExceedsLimitError < StandardError
end