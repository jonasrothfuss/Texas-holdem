require 'ruby-poker' #gem that compares 5-card-sets
require 'gameCard'

class Round
  include Mongoid::Document
  include Mongoid::Timestamps
  
  
  has_and_belongs_to_many :players
  has_many :communal_cards, :class_name => "Gamecard"
  has_many :hands
  
  
  belongs_to :game_room
  
  field :pot
  field :bigBlind
  field :smallBlind
  field :limit
  

  @deck

  
  
  #substitutes the constructor --> returns a new Round objects with the right configuration
  def self.newRound(actualPlayers) 
    round = Round.create()
    round.createDeck
    round.pot = 0
    round.players << actualPlayers
    return round
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
      winner.each{ |player|
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
      players.each{ |player|
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
    
    communal_cards.each {|card|
      possibleCardsArray << card.to_s
    }
    
    [1,2].each {|i|
      possibleCardsArray << getHandOf(player).getCard(i).to_s
    }
    
    #two dimensional array
    possilbleCombinations = possibleCardsArray.combination(5).to_a
    
    bestCombination =  PokerHand.new(possilbleCombinations[0])
    possilbleCombinations.shift
    
    possilbleCombinations.each { |comb|
      combObject = PokerHand.new(comb) 
      if combObject > bestCombination
        bestCombination = combObject
      end
    }
    
    return bestCombination
  end
  
 
  def servePlayerCards
    getCard
    self.players.each{ |player|
      hands << Hand.newHand(player, getCard, getCard)
    }
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
  
  
  def getCard
    card_string = @deck.delete_at(Random.rand(@deck.length))
    Gamecard.newCard(card_string[1], card_string[0])
  end
  
  
  def createDeck
    @deck=[]
    puts "CREATE DECK" #DELETE
    ['C','D','H','S'].each { |color|
      [2, 3, 4, 5, 6, 7, 8, 9, 'T', 'J', 'Q', 'A', 'K'].each { |number|
          @deck << number.to_s + color
      }
    } 
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
