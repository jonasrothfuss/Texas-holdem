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

  def move
    if stage_finished?
      self.stage += 1
      resolve_stage
      push_stage
    end

    next_player
    push_turn
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
      response = {status: self.hands.without(:round, :gamecards), cards: self.hands.where(player: player).only(:player, :current, :gamecards), default_card: {:image_path => GameCard.default_image_path}}
    else
      response = {status: self.hands.without(:round, :gamecards), cards: self.hands.only(:player, :current, :gamecards)}
    end

    return response
  end

  def add_turn(user, bet)
    hand = self.hands.where(current: true).first
    if hand.player.owner[:_id] == user[:_id]
      if bet == -1
        hand.fold = true
      else
        hand.place_bet(bet)
      end

      hand.action_count += 1

      hand.save
    else
      raise UnauthorizedError
    end
  end

  def next_player
    last = -1

    self.hands.each_with_index do |h, i|
      if h.current
        last = i
        h.current = false
        h.save
        break
      end

      if h.player.big_blind
        big_blind = i
      end
    end

    if last == -1
      last = big_blind
    end

    if last+1 >= self.hands.count
      last = -1
    end

    self.hands[last+1].current = true
    self.hands[last+1].save
  end

  def push_turn
    hands = self.hands.without(:round, :gamecards)
    players = self.players
    push = {hands: hands, players: players}
    Pusher.trigger("gameroom-#{self.game_room.id}", 'turn', push)
  end

  def stage_finished?
    bet = self.hands[0].bet

    self.hands.each do |h|
      if bet != h.bet
        return false
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
      hands = {status: self.hands.without(:round, :gamecards)}
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
    best_hand = find_best_hand(self.hands[0])

    self.hands.each do |h|
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

    self.pot = 0
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
