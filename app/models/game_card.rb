class GameCard
  include Mongoid::Document

  embedded_in :round
  embedded_in :hand

  field :suit #allowed: 'C', 'D', 'H', 'S'
  field :number # Ace = A, Jack = J, Queen = Q, King = K, ten = T, lowAce = L
  field :image_path

  def self.new_card(card_number, card_suit)
    return GameCard.new(number: card_number, suit: card_suit)
  end

  def self.default_image_path
    return 'assets/cards/x.svg'
  end

  def image_path
    self.image_path = 'assets/cards/' + self.to_s + '.svg'
  end

  def to_s
    return self.number.to_s + self.suit
  end

end