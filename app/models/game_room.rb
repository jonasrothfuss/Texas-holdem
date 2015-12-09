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

  def add_player(user, buyIn)
    check = self.players.active.where(owner: user)
    
    if buyIn <= 0 
      raise InvalidBuyInError
    end
    
    if check.count == 0
      player = Player.new_player(user, buyIn)
      self.players << player
      save
      status = "<b>#{user[:first_name]} #{user[:last_name]}</b> has joined"
      push = {player: player, status: status}
      Pusher.trigger("gameroom-#{id}", 'newplayer', push)
      update_lists
    end

    return self.players
  end

  def remove_player(user)
    check_active_round(user) if self.active

    player = Player.active.where(game_room: id, owner: user).first
    player.leave
    status = "<b>#{user[:first_name]} #{user[:last_name]}</b> has left"
    push = {player: player, status: status}
    Pusher.trigger("gameroom-#{id}", 'playerleft', push)

    if self.players.active.count > 0
      update_lists
    else
      close
    end
  end

  def check_active_round(user)
    round = self.rounds.first

    if round != nil
      check_player = round.players.active.where(owner: user)

      if check_player.count > 0
        round.remove_player(check_player.first)
      end
    end
  end

  def close
    self.closed = true
    save
    Pusher.trigger('gamerooms', 'closed', self.id.to_s)
  end

  def start
    if (!self.active && self.players.active.count >= 2)
      new_round
      self.active = true
      save
      Pusher.trigger('gamerooms', 'states', {gid: self.id.to_s, active: true})
    end
  end

  def new_round
    if self.players.active.count >= 2
      new_blinds
      round = Round.new_round(self.players.active, self.min_bet)
      round.initialise
      self.rounds << round
      status = "<b>New Round</b>: #{self.players.active.count} players. $#{self.min_bet} Big Blind/$#{self.min_bet/2} Small Blind"
      response = {players: self.players.active, newround: access_round, status: status}
      Pusher.trigger("gameroom-#{id}", 'newround', response)
      save
      round.move
    else
      self.active = false
      save
      Pusher.trigger("gameroom-#{id}", 'status', false)
      Pusher.trigger('gamerooms', 'states', {gid: self.id.to_s, active: false})
    end
  end

  def new_blinds
    last_big = false
    bb_assigned = false
    last_small = false
    sb_assigned = false

    self.players.active.each do |p|
      if last_big
        p.big_blind = true
        bb_assigned = true
        p.save
        break
      elsif p.big_blind
        p.big_blind = false
        last_big = true
        p.save
      end
    end

    self.players.active.each do |p|
      if last_small
        p.small_blind = true
        sb_assigned = true
        p.save
        break
      elsif p.small_blind
        p.small_blind = false
        last_small = true
        p.save
      end
    end

    if !last_small && !last_big
      p0 = self.players.active[0]
      p1 = self.players.active[1]

      p0.small_blind = true
      p1.big_blind = true

      p0.save
      p1.save
    end

    if last_big && !bb_assigned
      p0 = self.players.active[0]
      p0.big_blind = true
      p0.save
    end

    if last_small && !sb_assigned
      p0 = self.playes.active[0]
      p0.small_blind = true
      p0.save
    end

    save
  end

  def access_round
    round = self.rounds
    puts "_------------------------------------ ROUNDS " + round.to_s
    response = {:round => round.without(:communal_cards).first, :cards => round.first.access_cards}
    return response
  end

  def buyInOk?(buy_in)
    return buy_in <= self.limit
  end

  private

  def update_lists
    push = [{gid: self.id.to_s, list: Player.active.where(game_room: self.id).only(:id, :owner)}]
    Pusher.trigger('gamerooms', 'players', push)
  end
end


class BuyInExceedsLimitError < StandardError
end

class InvalidBuyInError < StandardError
end