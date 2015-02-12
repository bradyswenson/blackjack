require 'rubygems'
require 'sinatra'

set :sessions, true

use Rack::Session::Cookie, :key => 'rack.session',
                           :path => '/',
                           :secret => 'dhsndumw7263ns6y2mskd92wsh' 

BLACKJACK_AMOUNT = 21
DEALER_MIN_HIT_AMOUNT = 17

helpers do
  def calculate_total(cards)
    values = cards.map{|card| card[1] }

    total = 0
    values.each do |value|
      if value == "A"
        total += 11
      else
        total += (value.to_i == 0 ? 10 : value.to_i)
      end
    end

    #correct for Aces
    values.select{|value| value == "A"}.count.times do
      break if total <= BLACKJACK_AMOUNT
      total -= 10
    end

    total
  end

  def card_image(card)
    suit = case card[0]
      when 'H' then 'hearts'
      when 'D' then 'diamonds'
      when 'C' then 'clubs'
      when 'S' then 'spades'
    end

    value = card[1]
    if ['J', 'Q', 'K', 'A'].include?(value)
      value = case card[1]
        when 'J' then 'jack'
        when 'Q' then 'queen'
        when 'K' then 'king'
        when 'A' then 'ace'
      end
    end

    "<img src='/images/cards/#{suit}_#{value}.jpg' class='card_image'>"
  end

  def winner!(msg)
    @show_hit_stay_buttons = false
    @show_play_again_button = true
    @success = "<strong>#{session[:player_name]} wins!</strong> #{msg}"
  end

  def loser!(msg)
    @show_hit_stay_buttons = false
    @show_play_again_button = true
    @error = "<strong>#{session[:player_name]} loses!</strong> #{msg}"
  end

  def tie!(msg)
    @show_hit_stay_buttons = false
    @show_play_again_button = true
    @success = "<strong>It's a push!</strong> #{msg}"
  end

end

before do
  @show_hit_stay_buttons = true
end

get '/' do
  unless session[:player_name]
    redirect '/new_player'
  else 
    redirect '/game'
  end
  erb :index
end

get '/new_player' do
  erb :get_player_name
end

post '/new_player' do
  if params[:player_name].empty?
    @error = "Please add your name."
    halt erb(:get_player_name)
  end

  session[:player_name] = params[:player_name]
  redirect '/game'
end

get '/game' do
  session[:turn] = session[:player_name]

  # deck
  suits = ['H', 'D', 'C', 'S']
  values = ['2', '3', '4', '5', '6', '7', '8', '9', '10', 'J', 'Q', 'K', 'A']
  session[:deck] = suits.product(values).shuffle!

  # deal cards
  session[:dealer_cards] = []
  session[:player_cards] = []
  session[:dealer_cards] << session[:deck].pop
  session[:player_cards] << session[:deck].pop
  session[:dealer_cards] << session[:deck].pop
  session[:player_cards] << session[:deck].pop

  player_total = calculate_total(session[:player_cards])
  dealer_total = calculate_total(session[:dealer_cards])

  if dealer_total == BLACKJACK_AMOUNT
    session[:turn] = "dealer"
    loser!("Dealer hit blackjack.")  
  elsif dealer_total == BLACKJACK_AMOUNT
    session[:turn] = "dealer"
    winner!("You hit blackjack!") 
  end

  erb :game
end

post '/game/player/hit' do
  session[:player_cards] << session[:deck].pop

  player_total = calculate_total(session[:player_cards])

  if player_total == BLACKJACK_AMOUNT
    winner!("You hit blackjack!")  
  elsif player_total > BLACKJACK_AMOUNT
    loser!("Busted at #{player_total}.") 
  end
  erb :game
end

post '/game/player/stay' do
  @success = "You have chosen to stay."
  @show_hit_stay_buttons = false
  redirect '/game/dealer'
end

get '/game/dealer' do
  @show_hit_stay_buttons = false
  session[:turn] = "dealer"

  dealer_total = calculate_total(session[:dealer_cards])

  if dealer_total == BLACKJACK_AMOUNT
    loser!("Dealer hit blackjack.")
  elsif dealer_total > BLACKJACK_AMOUNT
    winner!("Dealer busted at #{dealer_total}.")
  elsif dealer_total >= DEALER_MIN_HIT_AMOUNT
    #dealer stays
    redirect '/game/compare'
  else
    #dealer hits
    @show_dealer_hit_button = true
  end
    
  erb :game
end

post '/game/dealer/hit' do
  session[:dealer_cards] << session[:deck].pop
  redirect 'game/dealer'
end

get '/game/compare' do
  @show_hit_stay_buttons = false

  player_total = calculate_total(session[:player_cards])
  dealer_total = calculate_total(session[:dealer_cards])

  if player_total < dealer_total
    loser!("#{session[:player_name]} stayed at #{player_total} and the dealer stayed at #{dealer_total}.")
  elsif player_total > dealer_total
    winner!("#{session[:player_name]} stayed at #{player_total} and the dealer stayed at #{dealer_total}.")
  else
    tie!("#{session[:player_name]} and the dealer both had #{player_total}.")
  end

  erb :game
end



