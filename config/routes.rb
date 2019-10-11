Rails.application.routes.draw do
  root 'blackjack#home'
  get 'blackjack/home'
  get 'blackjack/select_bet'
  get 'blackjack/game_bet'
  get 'blackjack/game_reset'
  get 'blackjack/game_hit'
  get 'blackjack/game_double'
  get 'blackjack/game_stand'
  get 'blackjack/game_stands'
  get 'blackjack/games/:n', :to => 'blackjack#games'
  get 'blackjack/games_hit1'
  get 'blackjack/games_hit2'
  get 'blackjack/games_hit3'
  get 'blackjack/games_hit4'
  get 'blackjack/games_stay'
  get 'blackjack/game_bet/:bet', :to => 'blackjack#game_bet'
  # For details on the DSL available within this file, see https://guides.rubyonrails.org/routing.html
end
