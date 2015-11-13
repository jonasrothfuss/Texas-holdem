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
    return self.create(pot: 0, players: players, big_blind: blind, small_blind: blind/2, active: true, communal_cards: [])
  end

  def initialise
    create_deck
    deal_communal
    deal_players
    self.stage = 1
    save
  end

  def start
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
      if(p.small_blind)
        bet = self.small_blind
      end
      if(p.big_blind)
        bet = self.big_blind
      end

      p.chips -= bet
      p.save

      self.hands << Hand.new_hand(p, get_card, get_card, bet)
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

    case stage
      when 1
        5.times do
          cards.push({:image_path => GameCard.default_image_path})
        end
      when 2
        cards = self.communal_cards.first(3)
        2.times do
          cards.push({:image_path => GameCard.default_image_path})
        end
      when 3
        cards = self.communal_cards.first(4)
        cards.push({:image_path => GameCard.default_image_path})
      else
        cards = self.communal_cards.first(5)
    end

    return cards
  end

  def access_hand(user)
    if(self.stage < 4)
      player = self.players.where(owner: user).first
      response = {hands: self.hands.without(:round, :gamecards), cards: self.hands.where(player: player).only(:player, :gamecards), default_card: {:image_path => GameCard.default_image_path}}
    else
      response = {hands: self.hands.without(:round, :gamecards), cards: self.hands.only(:player, :gamecards)}
    end

    return response
  end

  def next_player
    last_hand = false

    self.hands.each do |h, i|
      if(last_hand)
        h.current = true
        h.save
        break
      end

      if(h.current)
        last_hand = true
        h.current = false
        h.save
      end

      if(h.player.big_blind)
        big_blind = i
      end
    end

    if(!last_hand)
      if(big_blind+1 >= self.hands.count)
        big_blind = -1
      end

      self.hands[big_blind+1].current = true
      self.hands[big_blind+1].save
    end
  end

  def push_turn
    hand = self.hands.where(current: true).only(:player)
    Pusher.trigger("gameroom-#{self.game_room.id}", 'turn', hand)
  end

  #method handles one round
  def play
    #TODO: implement the flow of a round and may move this code to a controller
    createDeck
    servePlayerCards
    #TODO: ask players for their actions
    serveFlop
    #TODO: ask players for their actions
    serveTurn
    #TODO: ask players for their actions
    serveRiver
    #TODO: ask players for their actions
    winner = resolveWinner
    if winner.is_a?(Arrray) # =>split pot
      winner.each { |player|
        player.win(self.pot/winner.length)
      }
    else
      winner.win(self.pot)
    end
  end


  #resolves the winner of the round (naive implementation)
  #in case of mulitple winners (split pot) it returns an array of the winners
  def resolveWinner
    bestPlayer = players[0]
    bestPlayersHand = findBestCardCombinationOf(bestPlayer)
    splitpotCandidate = nil

    for n in 1...players.length do
      actualPlayersBestHand = findBestCardCombinationOf(players[n])
      if actualPlayersBestHand == bestPlayersHand #=> might be a split pot
        splitpotCandidate = actualPlayersBestHand
      elsif actualPlayersBestHand > bestPlayersHand
        bestPlayersHand = actualPlayersBestHand
        bestPlayer = players[n]
      end
    end

    if splitpotCandidate == bestPlayersHand # => split pot
      bestPlayer = [] # return value will be an array
      players.each { |player|
        if bestPlayersHand == findBestCardCombinationOf(player)
          bestPlayer << player
        end
      }
    end

    return bestPlayer
  end


  #returns PokerHand object (--> ruby-gem poker)
  def findBestCardCombinationOf(player)
    possibleCardsArray = []

    communal_cards.each { |card|
      possibleCardsArray << card.to_s
    }

    [1, 2].each { |i|
      possibleCardsArray << getHandOf(player).getCard(i).to_s
    }

    #two dimensional array
    possilbleCombinations = possibleCardsArray.combination(5).to_a

    bestCombination = PokerHand.new(possilbleCombinations[0])
    possilbleCombinations.shift

    possilbleCombinations.each { |comb|
      combObject = PokerHand.new(comb)
      if combObject > bestCombination
        bestCombination = combObject
      end
    }

    return bestCombination
  end

  #returns hand of specific player, if the player is not in the game r
  def getHandOf(specific_player)
    result = nil
    hands.each { |hand|
      if hand.player == specific_player
        result = hand
      end
    }
    if result == nil
      raise PlayerNotPartOfRoundError
    else
      return result
    end
  end

  def serveFlop
    self.communal_cards = []
    getCard
    3.times {
      self.communal_cards << getCard
    }
  end

  def serveTurn
    getCard
    self.communal_cards << getCard
  end

  def serveRiver
    getCard
    self.communal_cards << getCard
  end
end


class PlayerNotPartOfRoundError < StandardError
end
