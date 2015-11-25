class PokerHand
  def to_user_s
    s = String.new

    @hand.each do |h|
      s << h.to_user_s + " "
    end

    s << "(" + hand_rating + ")"

    return s
  end
end

class Card
  def to_user_s
    s = String.new(FACES[@face].chr)

    case SUITS[@suit].chr
      when 'c'
        s << "&clubs;"
      when 's'
        s << "&spades;"
      when 'h'
        s << "&hearts;</span>"
        s.prepend("<span class='red'>")
      when 'd'
        s << "&diams;</span>"
        s.prepend("<span class='red'>")
    end

    return s
  end
end