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
      next_player if self.stage < 5
      push_turn
      push_stage
    elsif self.active
      next_player
      push_turn
    end
  end

  def end_round(winning_hand)
    collect_bets
    allocate_winnings([winning_hand.player])
    @stage_status = "<b>#{winning_hand.player[:owner][:first_name]}</b> wins <b>$#{self.pot}</b>"
    push_stage(true)
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
    self.players.active.each do |p|
      bet = 0
      if p.small_blind
        bet = self.small_blind
      end
      if p.big_blind
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
      player = self.players.active.where(owner: user).first
      cards = self.hands.where(player: player).only(:player, :current, :gamecards)

      status = ""

      if cards.length > 0
        status = "Your Hand: <b>"
        cards.first.gamecards.each do |c|
          status << c.to_user_s + " "
        end
        status << "</b>"
      end

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
      @turn_status = "<b>#{user[:first_name]}</b> "

      if bet == -1
        @turn_status << "folded"
        fold(hand)
      else
        hand.place_bet(bet)

        if bet == 0
          @turn_status << "checked"
        else
          @turn_status << "bet <b>$#{bet}</b>"
        end

        hand.action_count += 1
        hand.save

        move
      end
    else
      raise UnauthorizedError
    end
  end

  def fold(hand)
    hand.fold = true
    hand.save

    hands = self.hands.where(:fold.ne => true)

    if hands.count == 1
      hand.current = false
      hand.save

      push_turn

      end_round(hands.first)
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

  def push_turn
    hands = self.hands.without(:round, :gamecards)
    players = self.players
    push = {hands: hands, players: players, status: @turn_status}
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

  def push_stage(finished=false)
    if self.stage == 5
      hands = access_hand
    else
      hands = {state: self.hands.without(:round, :gamecards)}
    end

    players = []
    self.hands.each do |h|
      players << h.player
    end

    cards = access_cards
    create_status(cards)

    push = {
        pot: self.pot,
        cards: cards,
        hands: hands,
        players: players,
        stage: self.stage,
        status: @stage_status,
        finished: finished
    }

    Pusher.trigger("gameroom-#{self.game_room.id}", 'stage', push)
  end

  def create_status(cards)
    if @stage_status == nil
      @stage_status = String.new

      case self.stage
        when 2
          @stage_status << "Flop: "
          (0..2).each do |i|
            @stage_status << cards[i].to_user_s + " "
          end
        when 3
          @stage_status << "Turn: #{cards[3].to_user_s}"
        when 4
          @stage_status << "River: #{cards[4].to_user_s}"
      end
    end
  end

  def resolve_winner
    best_players = []
    best_hands = []
    best_hands << find_best_hand(self.hands.where(:fold.ne => true).first)
    @stage_status = String.new

    self.hands.where(:fold.ne => true).each do |h|
      player_hand = find_best_hand(h)
      if player_hand == best_hands[0]
        best_hands << player_hand
        best_players << h.player
      elsif player_hand > best_hands[0]
        best_hands = []
        best_hands << player_hand
        best_players = Array(h.player)
      end
    end

    if best_players.count > 1
      (0...best_players.count).each do |i|
        @stage_status << "#{best_players[i].owner[:first_name]} - #{best_hands[i].to_user_s}, "
      end
      @stage_status << "split the pot of <b>$#{self.pot}</b>"
    else
      @stage_status << "#{best_players[0].owner[:first_name]} won <b>$#{self.pot}</b> with <b>#{best_hands[0].to_user_s}</b>"
    end

    self.hands.each do |h|
      h.current = (best_players.include? h.player) ? true : false
      h.save
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

  def remove_player(player)
    p player
    p_hand = self.hands.where(player: player.id).first
    self.pot += p_hand.collect_bet
    p_hand.fold = true
    p_hand.save

    hands = self.hands.where(:fold.ne => true)

    if hands.count == 1
      h = hands.first
      h.current = false
      h.save
      end_round(h)

      self.players.active.each do |p|
        p.big_blind = false
        p.small_blind = false
        p.save
      end

      Thread.new do
        sleep(5)
        GameRoom.find(self.game_room).new_round
      end
    elsif p_hand.current
      move
      p_hand.save
    end

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
