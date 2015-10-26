class Round
  include Mongoid::Document
  include Mongoid::Timestamps
  
  attr_reader :deck #just for development purposes
  
  has_and_belongs_to_many :players
  has_many :cards
  has_many :hands
  
  belongs_to :game_room
  
  field :communal_cards, type: Array
  
  @deck
  
  #method handles one round
  
  def self.newRound(actualPlayers) #add
    round = Round.create()
    round.createDeck
    round.players << actualPlayers
    return round
  end
  
  def play
    createDeck
    #TODO: implement the flow of a round and may move this code to a controller
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
      raise PlayerNotPartOfRound
    else
      return result
    end
  end
  
  def getCard
    card_string = @deck.delete_at(Random.rand(@deck.length))
    Card.newCard(card_string[1], card_string[0])
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
  
  
  
end

class PlayerNotPartOfRound < StandardError
end
