class GameCard
  include Mongoid::Document

  embedded_in :round
  embedded_in :hand

  field :suit #allowed: 'C', 'D', 'H', 'S'
  field :number # Ace = A, Jack = J, Queen = Q, King = K, ten = T, lowAce = L
  # field :image_path
  #
  #
  def self.new_card(card_number, card_suit)
    return GameCard.new(number: card_number, suit: card_suit)
  end
  #
  #
  # def to_s
  #     return self.number.to_s + color
  # end
  #
  #
  # def create_image_path
  #   case self.color
  #     when 'C'
  #       color_dir = 'clubs'
  #     when 'D'
  #       color_dir = 'diamonds'
  #     when 'H'
  #       color_dir = 'hearts'
  #     when 'S'
  #       color_dir = 'spades'
  #   end
  #   self.image_path = 'assets/cards/'+ color_dir + '/' + self.to_s + '.svg'
  # end

end