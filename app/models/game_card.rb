class GameCard
  include Mongoid::Document

  embedded_in :round
  embedded_in :hand

  field :number # Ace = A, Jack = J, Queen = Q, King = K, ten = T, lowAce = L
  field :suit #allowed: 'C', 'D', 'H', 'S'
  field :image_path

  def self.new_card(card_number, card_suit)
    return GameCard.new(number: card_number, suit: card_suit)
  end

  def self.default_image_path
    return 'assets/cards/x.svg'
  end

  def image_path
    self.image_path = 'assets/cards/' + to_s + '.svg'
  end

  def to_s
    return self.number.to_s + self.suit
  end

  def to_user_s
    s = String.new(self.number.to_s)

    case self.suit
      when 'C'
        s << "&clubs;"
      when 'S'
        s << "&spades;"
      when 'H'
        s << "&hearts;</span>"
        s.prepend("<span class='red'>")
      when 'D'
        s << "&diams;</span>"
        s.prepend("<span class='red'>")
    end

    return s
  end

end