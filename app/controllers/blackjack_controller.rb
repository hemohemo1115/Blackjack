
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

#require '../lib/blackjack'
require 'json'
$deckfile = './app/json/deck.json'
$gamefile = './app/json/game.json'
$gamesfile = './app/json/games.json'

class BlackjackController < ApplicationController
  #include Blackjack
  def home
=begin 
    session[:deck] = nil
    session[:phands] = nil
    session[:dhands] = nil 
=end    
    File.open($deckfile, 'w') do |file|
      data = {"deck"=>[]}
      JSON.dump(data, file)
    end
    File.open($gamefile, 'w') do |game|
      data = {"player"=>{"hands"=>[],"sum"=>nil,"bet"=>100,"betting"=>0}, "dealer"=>{"hands"=>[],"sum"=>nil}}
      JSON.dump(data,game)
    end
    File.open($gamesfile, 'w') do |file|
      data = {"player1":{"hands": [],"sum": nil}, "player2":{"hands": [],"sum": nil},"player3":{"hands": [],"sum": nil},"player4":{"hands": [],"sum": nil}, "dealer":{"hands": [],"sum": nil}}
      file.write JSON.pretty_generate(data)
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
    data = nil
    File.open($gamefile) do |file|
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
    deckdata = nil
    gamedata = nil
    File.open($deckfile) do |file|
      deckdata = JSON.load(file)
    end
    File.open($gamefile) do |file|
      gamedata = JSON.load(file)
    end
    gamedata["player"]["hands"] = []
    gamedata["dealer"]["hands"] = []
    deck = Deck.new(false)
    p = Player.new
    d = Dealer.new
    p.draw(deck,gamedata["player"]["hands"])
    d.draw(deck,gamedata["dealer"]["hands"])
    p.draw(deck,gamedata["player"]["hands"])
    @betting = params[:bet].to_i
    p.betting = params[:bet].to_i
    @phands = p.hands
    @dhands = d.hands
    @psum = p.total
    @dsum = d.total
    @bet = gamedata["player"]["bet"]
    if p.blackjack
      @bet = p.win
      @result = "you win　　あなたの残額は#{@bet}ドルです"
    end
    File.open($deckfile, 'w') do |file|
      deckdata["deck"] = deck.deck
      JSON.dump(deckdata, file)
    end
    File.open($gamefile, 'w') do |file|
      gamedata["player"]["hands"] = p.hands
      gamedata["player"]["sum"] = p.total
      gamedata["player"]["betting"] = @betting
      gamedata["player"]["bet"] = @bet
      gamedata["dealer"]["sum"] = d.total
      JSON.dump(gamedata, file)
    end
    render 'game.html.erb'
  end

  def game_reset
    p = Player.new
    gamedata = nil
    File.open($deckfile, 'w') do |file|
      deckdata = {"deck"=>[]}
      JSON.dump(deckdata, file)
    end
    File.open($gamefile) do |file|
      gamedata = JSON.load(file)
    end
    File.open($gamefile, 'w') do |file|
      gamedata["player"]["hands"] = []
      gamedata["player"]["sum"] = nil
      gamedata["player"]["betting"] = 0
      gamedata["player"]["bet"] = 100
      gamedata["dealer"]["hands"] = []
      gamedata["dealer"]["sum"] = nil
      JSON.dump(gamedata, file)
    end
    @bet = p.bet
    render 'select_bet.html.erb'
  end

  def game_hit
    deckdata = nil
    gamedata = nil
    File.open($deckfile) do |file|
      deckdata = JSON.load(file)
    end
    File.open($gamefile) do |file|
      gamedata = JSON.load(file)
    end
    deck = Deck.new(deckdata["deck"])
    p = Player.new
    d = Dealer.new
    p.draw(deck,gamedata["player"]["hands"])
    d.hands = gamedata["dealer"]["hands"]
    @phands = p.hands
    @dhands = d.hands
    @psum = p.total
    @dsum = d.total
    @betting = gamedata["player"]["betting"]
    @bet = gamedata["player"]["bet"]
    p.betting = gamedata["player"]["betting"]
    p.bet = gamedata["player"]["bet"]
    if p.nobust
      @psum
    else
      @psum = "bust"
      @bet = p.lose
      @result = "Player lose　　あなたの残額は#{@bet}ドルです"
    end
    File.open($deckfile, 'w') do |file|
      deckdata["deck"] = deck.deck
      JSON.dump(deckdata, file)
    end
    File.open($gamefile, 'w') do |file|
      gamedata["player"]["hands"] = p.hands
      gamedata["player"]["sum"] = p.total
      gamedata["player"]["betting"] = @betting
      gamedata["player"]["bet"] = @bet
      JSON.dump(gamedata, file)
    end
    render 'game.html.erb'
  end

  def game_double
    deckdata = nil
    gamedata = nil
    File.open($deckfile) do |file|
      deckdata = JSON.load(file)
    end
    File.open($gamefile) do |file|
      gamedata = JSON.load(file)
    end
    deck = Deck.new(deckdata["deck"])
    p = Player.new
    d = Dealer.new
    p.draw(deck,gamedata["player"]["hands"])
    d.hands = gamedata["dealer"]["hands"]
    @phands = p.hands
    @dhands = d.hands
    @psum = p.total
    @dsum = d.total
    gamedata["player"]["betting"] *= 2
    @betting = gamedata["player"]["betting"]
    @bet = gamedata["player"]["bet"]
    p.betting = gamedata["player"]["betting"]
    p.bet = gamedata["player"]["bet"]
    @flag = true
    if p.nobust
      @psum
    else
      @psum = "bust"
      @bet = p.lose
      @result = "Player lose　　あなたの残額は#{@bet}ドルです"
    end
    File.open($deckfile, 'w') do |file|
      deckdata["deck"] = deck.deck
      JSON.dump(deckdata, file)
    end
    File.open($gamefile, 'w') do |file|
      gamedata["player"]["hands"] = p.hands
      gamedata["player"]["sum"] = p.total
      gamedata["player"]["betting"] = @betting
      gamedata["player"]["bet"] = @bet
      JSON.dump(gamedata, file)
    end
    render 'game.html.erb'
  end

  def game_stand
    deckdata = nil
    gamedata = nil
    File.open($deckfile) do |file|
      deckdata = JSON.load(file)
    end
    File.open($gamefile) do |file|
      gamedata = JSON.load(file)
    end
    deck = Deck.new(deckdata["deck"])
    p = Player.new
    d = Dealer.new
    p.hands = gamedata["player"]["hands"]
    d.draw(deck,gamedata["dealer"]["hands"])
    @phands = p.hands
    @psum = p.total
    @dhands = d.hands
    @dsum = d.total
    p.betting = gamedata["player"]["betting"]
    p.bet = gamedata["player"]["bet"]
    @bet = gamedata["player"]["bet"]
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
    File.open($deckfile, 'w') do |file|
      deckdata["deck"] = deck.deck
      JSON.dump(deckdata, file)
    end
    File.open($gamefile, 'w') do |file|
      gamedata["player"]["bet"] = @bet
      gamedata["dealer"]["hands"] = d.hands
      gamedata["dealer"]["sum"] = d.total
      JSON.dump(gamedata, file)
    end
    render 'game.html.erb'
  end

  def game_stands
    gamesdata = nil
    deckdata = nil
    File.open($deckfile) do |file|
      deckdata = JSON.load(file)
    end
    File.open($gamesfile) do |file|
      gamesdata = JSON.load(file)
    end
    deck = Deck.new(deckdata["deck"])
    p = Player.new
    d = Dealer.new
    d.hands = gamesdata["dealer"]["hands"]
    @dhands = d.hands
    @dsum = d.total
    @pnumber = session[:pnumber]
    @presults = session[:presults]
    @flag = 1
    while d.judge_d
      d.draw(deck,gamesdata["dealer"]["hands"])
      @dhands = d.hands
      @dsum = d.total
    end
    if d.nobust
      gamesdata.each_with_index do |(p, v), i|
        if i < @pnumber.size
          @dsum
          if v["sum"] > @dsum && v["sum"] < 22
            @presults[i] = "Player#{i+1} win"
          elsif v["sum"] < @dsum
            @presults[i] = "Player#{i+1} lose"
          elsif v["sum"] == @dsum
            @presults[i] = "Player#{i+1} draw"
          end
        end
      end
    else
      @dsum = "bust"
      gamesdata.each_with_index do |(p, v), i|
        if @presults[i] == nil
          @presults[i] = "Player#{i+1} win"
        end
      end
    end
    @gamesdata = gamesdata
    session[:dhands] = d.hands
    File.open($deckfile, 'w') do |file|
      deckdata["deck"] = deck.deck
      JSON.dump(deckdata, file)
    end
    File.open($gamesfile, 'w') do |file|
      gamesdata["dealer"]["hands"] = d.hands
      gamesdata["dealer"]["sum"] = d.total
      file.write JSON.pretty_generate(gamesdata)
    end
    render 'games_stay.html.erb'
  end

  def games
    gamesdata = nil
    deckdata = nil
    File.open($deckfile) do |file|
      deckdata = JSON.load(file)
    end
    File.open($gamesfile) do |file|
      gamesdata = JSON.load(file)
    end
    deck = Deck.new(false)
    d = Dealer.new
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
    i = 1
    pclass.each do |p|
      p.draw(deck,gamesdata["player#{i}"]["hands"])
      i += 1
    end
    d.draw(deck,gamesdata["dealer"]["hands"])
    i = 1
    pclass.each do |p|
      p.draw(deck,gamesdata["player#{i}"]["hands"])
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
      @psums[i] = pclass[i].total
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
    File.open($deckfile, 'w') do |file|
      deckdata["deck"] = deck.deck
      JSON.dump(deckdata, file)
    end
    i = 0
    params[:n].to_i.times do
      File.open($gamesfile, 'w') do |file|
        gamesdata["player#{i+1}"]["hands"] = pclass[i].hands
        gamesdata["player#{i+1}"]["sum"] = pclass[i].total
        file.write JSON.pretty_generate(gamesdata)
      end
      i += 1
    end
    File.open($gamesfile, 'w') do |file|
      gamesdata["dealer"]["hands"] = d.hands
      gamesdata["dealer"]["sum"] = d.total
      file.write JSON.pretty_generate(gamesdata)
    end
    @gamesdata = gamesdata
    session[:pnumber] = pnumber
    session[:pclass] = pclass
    session[:presults] = @presults
    session[:count] = @count
    render 'games.html.erb'
  end

  def games_hit1
    deckdata = nil
    gamesdata = nil
    File.open($deckfile) do |file|
      deckdata = JSON.load(file)
    end
    File.open($gamesfile) do |file|
      gamesdata = JSON.load(file)
    end
    deck = Deck.new(deckdata["deck"])
    p = Player.new
    d = Dealer.new
    p.draw(deck,gamesdata["player1"]["hands"])
    d.hands = gamesdata["dealer"]["hands"]
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
      @presults[0] = "Player1 lose"
    end
    @gamesdata = gamesdata
    session[:presults] = @presults
    File.open($deckfile, 'w') do |file|
      deckdata["deck"] = deck.deck
      JSON.dump(deckdata, file)
    end
    File.open($gamesfile, 'w') do |file|
      gamesdata["player1"]["hands"] = p.hands
      gamesdata["player1"]["sum"] = p.total
      file.write JSON.pretty_generate(gamesdata)
    end
    render 'games.html.erb'
  end

  def games_hit2
    deckdata = nil
    gamesdata = nil
    File.open($deckfile) do |file|
      deckdata = JSON.load(file)
    end
    File.open($gamesfile) do |file|
      gamesdata = JSON.load(file)
    end
    deck = Deck.new(deckdata["deck"])
    p = Player.new
    d = Dealer.new
    p.draw(deck,gamesdata["player2"]["hands"])
    d.hands = gamesdata["dealer"]["hands"]
    @phands = p.hands
    @dhands = d.hands
    @psum = p.total
    @dsum = d.total
    @pnumber = session[:pnumber]
    @presults = session[:presults]
    @count = session[:count]
    if p.nobust
      @psum
    else
      @psum = "bust"
      @presults[1] = "Player2 lose"
    end
    @gamesdata = gamesdata
    session[:presults] = @presults
    File.open($deckfile, 'w') do |file|
      deckdata["deck"] = deck.deck
      JSON.dump(deckdata, file)
    end
    File.open($gamesfile, 'w') do |file|
      gamesdata["player2"]["hands"] = p.hands
      gamesdata["player2"]["sum"] = p.total
      file.write JSON.pretty_generate(gamesdata)
    end
    render 'games_stay.html.erb'

  end

  def games_hit3
    deckdata = nil
    gamesdata = nil
    File.open($deckfile) do |file|
      deckdata = JSON.load(file)
    end
    File.open($gamesfile) do |file|
      gamesdata = JSON.load(file)
    end
    deck = Deck.new(deckdata["deck"])
    p = Player.new
    d = Dealer.new
    p.draw(deck,gamesdata["player3"]["hands"])
    d.hands = gamesdata["dealer"]["hands"]
    @phands = p.hands
    @dhands = d.hands
    @psum = p.total
    @dsum = d.total
    @pnumber = session[:pnumber]
    @presults = session[:presults]
    @count = session[:count]
    if p.nobust
      @psum
    else
      @psum = "bust"
      @presults[2] = "Player3 lose"
    end
    @gamesdata = gamesdata
    session[:presults] = @presults
    File.open($deckfile, 'w') do |file|
      deckdata["deck"] = deck.deck
      JSON.dump(deckdata, file)
    end
    File.open($gamesfile, 'w') do |file|
      gamesdata["player3"]["hands"] = p.hands
      gamesdata["player3"]["sum"] = p.total
      file.write JSON.pretty_generate(gamesdata)
    end
    render 'games_stay.html.erb'
  end

  def games_hit4
    deckdata = nil
    gamesdata = nil
    File.open($deckfile) do |file|
      deckdata = JSON.load(file)
    end
    File.open($gamesfile) do |file|
      gamesdata = JSON.load(file)
    end
    deck = Deck.new(deckdata["deck"])
    p = Player.new
    d = Dealer.new
    p.draw(deck,gamesdata["player4"]["hands"])
    d.hands = gamesdata["dealer"]["hands"]
    @phands = p.hands
    @dhands = d.hands
    @psum = p.total
    @dsum = d.total
    @pnumber = session[:pnumber]
    @presults = session[:presults]
    @count = session[:count]
    if p.nobust
      @psum
    else
      @psum = "bust"
      @presults[3] = "Player4 lose"
    end
    @gamesdata = gamesdata
    session[:presults] = @presults
    File.open($deckfile, 'w') do |file|
      deckdata["deck"] = deck.deck
      JSON.dump(deckdata, file)
    end
    File.open($gamesfile, 'w') do |file|
      gamesdata["player4"]["hands"] = p.hands
      gamesdata["player4"]["sum"] = p.total
      file.write JSON.pretty_generate(gamesdata)
    end
    render 'games_stay.html.erb'
  end

  def games_stay
    session[:count] += 1
    deckdata = nil
    gamesdata = nil
    File.open($deckfile) do |file|
      deckdata = JSON.load(file)
    end
    File.open($gamesfile) do |file|
      gamesdata = JSON.load(file)
    end
    deck = Deck.new(deckdata["deck"])
    d = Dealer.new
    d.hands = gamesdata["dealer"]["hands"]
    @dhands = d.hands
    @dsum = d.total
    @gamesdata = gamesdata
    @pnumber = session[:pnumber]
    @presults = session[:presults]
    @count = session[:count]
    session[:count] = @count
    render 'games_stay.html.erb'
  end
end