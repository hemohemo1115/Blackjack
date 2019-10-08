=begin
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
=end

require './app/lib/blackjack'
require 'json'
$file = './app/json/deck.json'
$gamefile = './app/json/game.json'

class BlackjackController < ApplicationController
  #include Blackjack
  def home
=begin 
    session[:deck] = nil
    session[:phands] = nil
    session[:dhands] = nil 
=end    
    File.open($file, 'w') do |file|
      data = {"deck"=>[]}
      JSON.dump(data, file)
    end
    File.open($gamefile, 'w') do |game|
      data = {"player"=>{"hands"=>[],"sum"=>nil,"bet"=>100,"betting"=>0}, "dealer"=>{"hands"=>[],"sum"=>nil}}
      JSON.dump(data,game)
    end
    render 'home.html.erb'
  end

  def select_bet
    p = Player.new
=begin 
    p = Player.new
    if session[:bet]
      @bet = session[:bet]
    else
      @bet = p.bet
    end
=end
    File.open("$gamefile") do |file|
      data = JSON.load(file)
    end
    if data["player"]["bet"]
      @bet = data["player"]["bet"]
    else
      @bet = p.bet
    end
    render 'select_bet.html.erb'
  end

  def game_bet
=begin 
    session[:deck] = nil
    session[:phands] = nil
    session[:dhands] = nil
    deck = Deck.new(session[:deck])
    p = Player.new
    d = Dealer.new
    p.draw(deck,session[:phands])
    d.draw(deck,session[:dhands])
    p.draw(deck,session[:phands])
    @betting = params[:bet].to_i
    p.betting = params[:bet].to_i
    @phands = p.hands
    @dhands = d.hands
    @psum = p.total
    @dsum = d.total
    @bet = session[:bet]
    if p.blackjack
      @bet = p.win
      @result = "you win　　あなたの残額は#{@bet}ドルです"
    end
    session[:deck] = deck.deck
    session[:phands] = p.hands
    session[:dhands] = d.hands
    session[:betting] = @betting
    session[:bet] = @bet 
=end
    
    render 'game.html.erb'
  end

  def game_reset
    p = Player.new
    session[:deck] = nil
    session[:phands] = nil
    session[:dhands] = nil
    session[:bet] = p.bet
    @bet = session[:bet]
    render 'select_bet.html.erb'
  end

  def game_hit
    deck = Deck.new(session[:deck])
    p = Player.new
    d = Dealer.new
    p.draw(deck,session[:phands])
    d.hands = session[:dhands]
    @phands = p.hands
    @dhands = d.hands
    @psum = p.total
    @dsum = d.total
    @betting = session[:betting]
    p.betting = session[:betting]
    @bet = session[:bet]
    p.bet = session[:bet]
    if p.nobust
      @psum
    else
      @psum = "bust"
      @bet = p.lose
      @result = "Player lose　　あなたの残額は#{@bet}ドルです"
    end
    session[:deck] = deck.deck
    session[:phands] = p.hands
    session[:dhands] = d.hands
    session[:bet] = @bet
    render 'game.html.erb'
  end

  def game_double
    deck = Deck.new(session[:deck])
    p = Player.new
    d = Dealer.new
    @flag = true
    p.draw(deck,session[:phands])
    d.hands = session[:dhands]
    @phands = p.hands
    @dhands = d.hands
    @psum = p.total
    @dsum = d.total
    session[:betting] *= 2
    @betting = session[:betting]
    p.betting = session[:betting]
    @bet = session[:bet]
    p.bet = session[:bet]
    if p.nobust
      @psum
    else
      @psum = "bust"
      @bet = p.lose
      @result = "Player lose　　あなたの残額は#{@bet}ドルです"
    end
    session[:deck] = deck.deck
    session[:phands] = p.hands
    session[:dhands] = d.hands
    session[:bet] = @bet
    render 'game.html.erb'
  end

  def game_stand
    deck = Deck.new(session[:deck])
    p = Player.new
    d = Dealer.new
    p.hands = session[:phands]
    d.draw(deck,session[:dhands])
    @phands = session[:phands]
    @psum = p.total
    @dhands = d.hands
    @dsum = d.total
    p.betting = session[:betting]
    p.bet = session[:bet]
    @bet = session[:bet]
    while d.judge_d
      d.draw(deck,session[:dhands])
      @dhands = d.hands
      @dsum = d.total
    end
    if d.nobust
      @dsum
      if p.total > @dsum && p.total < 22
        @bet = p.win
        @result = "Player win　　あなたの残額は#{@bet}ドルです"
      elsif p.total < @dsum
        @bet = p.lose
        @result = "Player lose　　あなたの残額は#{@bet}ドルです"
      elsif p.total == @dsum
        @result = "draw　　あなたの残額は#{@bet}ドルです"
      end
    else
      @dsum = "bust"
      @bet = p.win
      @result = "Player win　　あなたの残額は#{@bet}ドルです"
    end
    
    session[:deck] = deck.deck
    session[:dhands] = d.hands
    session[:bet] = @bet
    render 'game.html.erb'
  end

  def game_stands
    deck = Deck.new(session[:deck])
    p = Player.new
    d = Dealer.new
    d.draw(deck,session[:dhands])
    @dhands = d.hands
    @dsum = d.total
    @pnumber = session[:pnumber]
    @pclass = session[:pclass]
    @presults = session[:presults]
    @flag = 1
    while d.judge_d
      d.draw(deck,session[:dhands])
      @dhands = d.hands
      @dsum = d.total
    end
    if d.nobust
      @pclass.each_with_index do |p,i|
        @dsum
        if p.total > @dsum && p.total < 22
          @presults[i] = "Player#{i+1} win"
        elsif p.total < @dsum
          @presults[i] = "Player#{i+1} lose"
        elsif p.total == @dsum
          @presults[i] = "Player#{i+1} draw"
        end
      end
    else
      @dsum = "bust"
      @pclass.each_with_index do |p,i|
        if @presults[i] == nil
          @presults[i] = "Player#{i+1} win"
        end
      end
    end
    session[:deck] = deck.deck
    session[:dhands] = d.hands
    render 'games_stay.html.erb'
  end

  def games
    session[:deck] = nil
    i = 0
    params[:n].to_i.times do
      session["p#{i}hands".to_sym] = nil
      i += 1
    end
    session[:dhands] = nil
    deck = Deck.new(session[:deck])  
    i = 0
    pnumber = []
    pclass = []
    params[:n].to_i.times do
      pnumber[i] = i+1
      pclass[i] = Player.new
      i += 1
    end
    @pnumber = pnumber
    @pclass = pclass
    @psums = []
    @presults = []
    @plhands = []
    @count = 1
    d = Dealer.new
    i = 0
    pclass.each do |p|
      p.draw(deck,session["p#{i}hands".to_sym])
      i += 1
    end
    d.draw(deck,session[:dhands])
    i = 0
    pclass.each do |p|
      p.draw(deck,session["p#{i}hands".to_sym])
      i += 1
    end
    i = 0
    params[:n].to_i.times do
      @plhands[i] = pclass[i].hands
      i += 1
    end
    @dhands = d.hands
    i = 0
    params[:n].to_i.times do
      @psums = pclass[i].total
      i += 1
    end
    @dsum = d.total
    i = 0
    pclass.each do |p|
      if p.blackjack
        @presults[i] = "Player#{i+1} win"
      end
      i += 1
    end
    session[:deck] = deck.deck
    i = 0
    params[:n].to_i.times do
      session["p#{i}hands".to_sym] = pclass[i].hands
      session["p#{i}result".to_sym] = @presults[i]
      i += 1
    end
    session[:dhands] = d.hands
    session[:pnumber] = pnumber
    session[:pclass] = pclass
    session[:presults] = @presults
    session[:count] = @count
    puts pclass
    puts session[:pclass]
    render 'games.html.erb'
  end

  def games_hit1
    deck = Deck.new(session[:deck])
    p = Player.new
    d = Dealer.new
    p.draw(deck,session[:p0hands])
    d.hands = session[:dhands]
    @phands = p.hands
    @dhands = d.hands
    @psum = p.total
    @dsum = d.total
    @pnumber = session[:pnumber]
    @pclass = session[:pclass]
    @presults = session[:presults]
    @count = session[:count]
    puts session[:pclass]
    puts @pclass
    puts "hoge"
    if p.nobust
      @psum
    else
      @psum = "bust"
      @presults[0] = "Player1 lose"
    end
    session[:deck] = deck.deck
    session[:p0hands] = p.hands
    session[:dhands] = d.hands
    session[:presults] = @presults
    @pclass[0]["hands"] = p.hands
    session[:pclass] = @pclass
    render 'games.html.erb'
  end

  def games_hit2
    deck = Deck.new(session[:deck])
    p = Player.new
    d = Dealer.new
    p.draw(deck,session[:p1hands])
    d.hands = session[:dhands]
    @phands = p.hands
    @dhands = d.hands
    @psum = p.total
    @dsum = d.total
    @pnumber = session[:pnumber]
    @pclass = session[:pclass]
    @presults = session[:presults]
    @count = session[:count]
    if p.nobust
      @psum
    else
      @psum = "bust"
      @presults[1] = "Player2 lose"
    end
    session[:deck] = deck.deck
    session[:p1hands] = p.hands
    session[:dhands] = d.hands
    session[:presults] = @presults
    @pclass[1].hands = p.hands
    session[:pclass] = @pclass
    render 'games_stay.html.erb'

  end

  def games_hit3
    deck = Deck.new(session[:deck])
    p = Player.new
    d = Dealer.new
    p.draw(deck,session[:p2hands])
    d.hands = session[:dhands]
    @phands = p.hands
    @dhands = d.hands
    @psum = p.total
    @dsum = d.total
    @pnumber = session[:pnumber]
    @pclass = session[:pclass]
    @presults = session[:presults]
    @count = session[:count]
    if p.nobust
      @psum
    else
      @psum = "bust"
      @presults[2] = "Player3 lose"
    end
    session[:deck] = deck.deck
    session[:p2hands] = p.hands
    session[:dhands] = d.hands
    session[:presults] = @presults
    @pclass[2].hands = p.hands
    session[:pclass] = @pclass
    render 'games_stay.html.erb'
  end

  def games_hit4
    deck = Deck.new(session[:deck])
    p = Player.new
    d = Dealer.new
    #@p2hands = session[:p2hands]
    #@p3hands = session[:p3hands]
    p.draw(deck,session[:p3hands])
    d.hands = session[:dhands]
    @phands = p.hands
    @dhands = d.hands
    @psum = p.total
    @dsum = d.total
    @pnumber = session[:pnumber]
    @pclass = session[:pclass]
    @presults = session[:presults]
    @count = session[:count]
    if p.nobust
      @psum
    else
      @psum = "bust"
      @presults[3] = "Player4 lose"
    end
    session[:deck] = deck.deck
    session[:p3hands] = p.hands
    session[:dhands] = d.hands
    session[:presults] = @presults
    @pclass[3].hands = p.hands
    session[:pclass] = @pclass
    render 'games_stay.html.erb'
  end

  def games_stay
    session[:count] += 1
    deck = Deck.new(session[:deck])
    d = Dealer.new
    d.hands = session[:dhands]
    @dhands = d.hands
    @dsum = d.total
    @pnumber = session[:pnumber]
    @pclass = session[:pclass]
    @presults = session[:presults]
    @count = session[:count]
    session[:deck] = deck.deck
    session[:dhands] = d.hands
    session[:presults] = @presults
    session[:count] = @count
    render 'games_stay.html.erb'
  end
end