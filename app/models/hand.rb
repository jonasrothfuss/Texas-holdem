class Hand
  include Mongoid::Document
  include Mongoid::Timestamps
  
  has_one :player
  has_many :cards
  
  
  belongs_to :round
  
  def self.newHand(player, card1, card2)
    puts player #DELETE
    hand = Hand.create
    puts hand #DELETE
    hand.player = player
    puts card1.to_s + "----" + card2.to_s
    hand.cards << card1
    hand.cards << card2
    return hand
  end
  
  
  def getCard(card_index) #index can be 1 or 2
    return cards[card_index-1]
  end
end