class Card
    include Mongoid::Document
    
    
    belongs_to :round
    belongs_to :hand
    
    field :color #allowed: 'C', 'D', 'H', 'S'
    field :number # Ace = A, Jack = J, Queen = Q, King = K, ten = T, lowAce = L
    field :image_path
    
    
    def self.newCard(card_color, card_number)
      puts "INITIALIZE CARD: color: " + card_color + " number: " + card_number.to_s #DELETE
      card = Card.new(color: card_color, number: card_number)
      card.create_image_path
      return card
    end
    
    
    def to_s
        return self.number.to_s + color
    end
    
    
    def create_image_path
      case self.color
        when 'C'
          color_dir = 'clubs'
        when 'D'
          color_dir = 'diamonds'
        when 'H'
          color_dir = 'hearts'
        when 'S'
          color_dir = 'spades'
      end
      self.image_path = 'assets/cards/'+ color_dir + '/' + self.to_s + '.svg'
    end
    
end