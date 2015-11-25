require 'ruby-poker' #gem that compares 5-card-sets

class Round
  include Mongoid::Document
  include Mongoid::Timestamps

  has_and_belongs_to_many :players
  embeds_many :communal_cards, :class_name => "GameCard"
  has_many :hands

  belongs_to :game_room

  field :pot
  field :small_blind
  field :big_blind
  field :stage, type: Integer
  field :active, type: Boolean

  default_scope -> { where(active: true) }

  def self.new_round(players, blind)
    return self.create(pot: 0, players: players, small_blind: blind/2, big_blind: blind, active: true, communal_cards: [])
  end

  def initialise
    create_deck
    deal_communal
    deal_players
    self.stage = 1
    save
  end

  def move(status = nil)
    if stage_finished?
      self.stage += 1
      resolve_stage
      next_player
      push_turn(status)
      push_stage
    elsif self.active
      next_player
      push_turn(status)
    end
  end

  def create_deck
    @deck=[]
    ['C', 'D', 'H', 'S'].each do |color|
      [2, 3, 4, 5, 6, 7, 8, 9, 'T', 'J', 'Q', 'K', 'A'].each do |number|
        @deck << number.to_s + color
      end
    end
  end

  def deal_players
    self.players.each do |p|
      bet = 0
      if (p.small_blind)
        bet = self.small_blind
      end
      if (p.big_blind)
        bet = self.big_blind
      end

      hand = Hand.new_hand(p, get_card, get_card)
      hand.place_bet(bet)
      self.hands << hand
    end

    save
  end

  def deal_communal
    5.times do
      c = get_card
      self.communal_cards << GameCard.new_card(c[0], c[1])
    end
    save
  end

  def get_card
    return @deck.delete_at(Random.rand(@deck.length))
  end

  def access_cards
    cards = []
    fill = 0

    case stage
      when 1
        fill = 5
      when 2
        cards = self.communal_cards.first(3)
        fill = 2
      when 3
        cards = self.communal_cards.first(4)
        fill = 1
      else
        cards = self.communal_cards.first(5)
    end

    fill.times do
      cards.push({:image_path => GameCard.default_image_path})
    end

    return cards
  end

  def access_hand(user={})
    if self.stage < 5
      player = self.players.where(owner: user).first
      cards = self.hands.where(player: player).only(:player, :current, :gamecards)
      status = "Your Hand: <span class='bold'>"
      cards.first.gamecards.each do |c|
        status << c.to_user_s + " "
      end
      status << "</span>"

      response = {
          state: self.hands.without(:round, :gamecards),
          cards: cards,
          default_card: {:image_path => GameCard.default_image_path},
          status: status
      }
    else
      response = {
          state: self.hands.without(:round, :gamecards),
          cards: self.hands.where(:fold.ne => true).only(:player, :current, :gamecards)
      }
    end

    return response
  end

  def add_turn(user, bet)
    hand = self.hands.where(current: true).first
    if hand.player.owner[:_id] == user[:_id]
      status = "<span class='bold'>#{user[:first_name]}</span> "

      if bet == -1
        fold(hand)
        status << "folded"
      else
        hand.place_bet(bet)

        if bet == 0
          status << "checked"
        else
          status << "bet $#{bet}"
        end

        hand.action_count += 1
        hand.save

        move(status)
      end
    else
      raise UnauthorizedError
    end
  end

  def fold(hand)
    hand.fold = true
    hand.save

    hands = self.hands

    if hands.count == 1
      h = hands.first

      collect_bets
      allocate_winnings([h.player])
      push_stage
    else
      hand.action_count += 1
      hand.save

      move
    end
  end

  def next_player
    nxt = -1
    bb = nil

    self.hands.each_with_index do |h, i|
      if h.current
        nxt = i+1
        h.current = false
        h.save
      end

      if h.player.big_blind
        bb = i
      end
    end

    if nxt == -1
      nxt = bb+1
    end

    found = false
    until found
      if nxt >= self.hands.count
        nxt = 0
      end

      if !self.hands[nxt].fold
        found = true
      else
        nxt += 1
      end
    end

    self.hands[nxt].current = true
    self.hands[nxt].save
  end

  def push_turn(status)
    hands = self.hands.without(:round, :gamecards)
    players = self.players
    push = {hands: hands, players: players, status: status}
    Pusher.trigger("gameroom-#{self.game_room.id}", 'turn', push)
  end

  def stage_finished?
    bet = nil
    hands = self.hands.where(:fold.ne => true)

    hands.each do |h|
      if bet != h.bet
        if bet != nil
          return false
        else
          bet = h.bet
        end
      end

      if h.action_count == 0
        return false
      end
    end

    return true
  end

  def resolve_stage
    collect_bets
    self.hands.each do |h|
      h.current = false
      h.action_count = 0
      h.save
    end

    if self.stage == 5
      resolve_winner
    end
  end

  def collect_bets
    self.hands.each do |h|
      self.pot += h.collect_bet
    end

    save
  end

  def push_stage
    if self.stage == 5
      hands = access_hand
    else
      hands = {state: self.hands.without(:round, :gamecards)}
    end

    players = []
    self.hands.each do |h|
      players << h.player
    end

    push = {pot: self.pot, cards: access_cards, hands: hands, players: players}

    Pusher.trigger("gameroom-#{self.game_room.id}", 'stage', push)
  end

  def resolve_winner
    best_players = []
    best_hand = find_best_hand(self.hands.where(:fold.ne => true).first)

    self.hands.where(:fold.ne => true).each do |h|
      player_hand = find_best_hand(h)
      if player_hand == best_hand
        best_players << h.player
      elsif player_hand > best_hand
        best_hand = player_hand
        best_players = Array(h.player)
      end
    end

    allocate_winnings(best_players)
  end

  def find_best_hand(hand)
    cards = []

    self.communal_cards.each do |card|
      cards << card.to_s
    end

    [0, 1].each do |i|
      cards << hand.get_card(i).to_s
    end

    combinations = cards.combination(5).to_a

    best = PokerHand.new(combinations[0])

    combinations.each do |c|
      obj = PokerHand.new(c)
      if obj > best
        best = obj
      end
    end

    return best
  end

  def allocate_winnings(winners)
    split = self.pot / winners.count

    winners.each do |w|
      w.chips += split
      w.save
    end

    self.active = false
    save
  end
end

class UnauthorizedError < StandardError
  def status
    return 403
  end
end

class PlayerNotPartOfRoundError < StandardError
end
