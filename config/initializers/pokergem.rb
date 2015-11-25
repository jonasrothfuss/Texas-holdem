class Card
  def to_s
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