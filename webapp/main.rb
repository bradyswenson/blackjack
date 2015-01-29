require 'rubygems'
require 'sinatra'

use Rack::Session::Cookie, :key => 'rack.session',
                           :path => '/',
                           :secret => 'dhsndumw7263ns6y2mskd92wsh' 


get '/' do
  unless session[:player_name]
    redirect '/new_player'
  end
  erb :index
end

get '/new_player' do
  erb :get_player_name
end

post '/new_player' do
  session[:player_name] = params['username']
end



