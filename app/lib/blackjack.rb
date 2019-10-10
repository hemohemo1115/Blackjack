module Blackjack
class Deck
    attr_accessor :deck
    def initialize(deck)
      if deck
        @deck = deck
      else
        @deck = [*1..52]
        @deck.shuffle! #山札のシャッフル
      end
    end
  
    
    
    def distribution
      @deck.pop
    end
    
end

  class Card
    def initialize(number)
      @number = number
    end
  
    attr_accessor :number
  
    def stringify
      for i in @deck
        @number = (i-1)%13 + 1
        if i/13 == 0
          @deck[@index] = {"S" => @number}
        elsif i/13 == 1
          @deck[@index] = {"C" => @number}
        elsif i/13 == 2
          @deck[@index] = {"D" => @number}
        elsif i/13 == 3
          @deck[@index] = {"H" => @number}
        end
        @index += 1
      end
    end
  
  end
  
  class Player
    attr_accessor :hands, :sum, :bet, :betting
    def initialize
      @hands = []
      @sum = 0
      @bet = 100
      @betting = 0
    end
  
    def hands
      @hands
    end
    
    def draw(deck,hands)
      if hands
        @hands = hands
        @hands.push(deck.distribution)
      else
        @hands.push(deck.distribution)
      end
    end
  
    def a_is
      flag = false
      @hands.each{ |number|
        if number%13 == 1
          flag = true
        end
      }
      return flag
    end
    
    def total
      flag = false
      @sum = 0
      for number in @hands
          #J,Q,Kの処理
          if number%13 >10 || number%13 == 0
            number = 10
          end
          #Aの処理
          if number%13 == 1 && (@sum+11) < 22
            number = 11
            flag = true
          elsif number%13 == 1 && (@sum+11) > 21
            number = 1
          end
          @sum += number%13
          if @sum > 21 && flag
            @sum -= 10
            flag = false
          end
      end
      return @sum
    end
  
    def nobust
      if @sum > 21
        false
      else
        true
      end
    end
  
    def blackjack
      if @hands.size == 2 && @sum == 21
        true
      else
        false
      end
    end
  
    def win
      return @bet += @betting
    end
  
    def lose
      return @bet -= @betting
    end
    
  end
  
  class Dealer < Player
    def judge_d
      if @sum < 17
        true
      end
    end
    
  end
end