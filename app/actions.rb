# Homepage
get '/' do
  redirect :'games'
end

# Page: Bet on a game
get '/games' do
  erb :'games/index'
end

# Page: Game details
get '/games/:id' do
  erb :'games/show'
end

# Creat a bet for a game
post 'games/:id/bets' do
  redirect :'games' # When saved successfully
end

# Page: My bets
get '/bets' do
  erb :'bets/index'
end

# Page: Leader board
get '/leaderboard' do
  erb :'users/leaderboard'
end

# Page: Custom Board
get '/customboard' do
  erb :'users/customeboard'
end
