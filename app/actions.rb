helpers do
  def current_user
    @current_user ||= User.find_by(id: session[:user_id])
  end

  def format_datetime(datetime)
    datetime.strftime("%F %I:%M%p")
  end

  def show_game(game)
    "#{game.teams.first.name} vs #{game.teams.last.name}"
  end

  def show_game_result(game)
    if ['Final', 'InProgess'].include?(game.status)
      "#{game.game_teams.first.score} : #{game.game_teams.last.score}"
    end
  end

  def show_bet_result(bet)
    bet.profit_points ||= 0
    result = (bet.profit_points - bet.points).to_s

    case bet.game_team.result
    when 1
      'Won ' + result + ' points'
    when -1
      'Lost ' + result + ' points'
    when 0
      "Tie: #{bet.points} returned back to your account."
    end
  end

  def get_points
    profit = Bet.where(user_id = current_user.id).sum("profit_points")
    wager = Bet.where(user_id = current_user.id).sum("points")
    current_user.points.to_i + profit - wager
  end

  def bet_count
    current_user.bets.count
  end

  def bet_won
    Bet.joins(:game_team).where("user_id = ? AND game_teams.result = ?", current_user.id, 1).count
  end

  def bet_loss
    Bet.joins(:game_team).where("user_id = ? AND game_teams.result = ?", current_user.id, -1).count
  end

  def bet_tie
    Bet.joins(:game_team).where("user_id = ? AND game_teams.result = ?", current_user.id, 0).count
  end

  def bet_in_progress
    profit = Bet.joins(:game_team).where("user_id = ? AND game_teams.result = ?", current_user.id, nil).count
  end

  def bet_completed
    bet_count - bet_in_progress
  end

  def points_in_progress
    Bet.joins(:game_team).where("user_id = ? AND game_teams.result = ?", current_user.id, nil).sum("points")
  end

  def points_invested_won
    Bet.joins(:game_team).where("user_id = ? AND game_teams.result = ?", current_user.id, 1).sum("points")
  end

  def points_gain_won
    Bet.joins(:game_team).where("user_id = ? AND game_teams.result = ?", current_user.id, 1).sum("points")
  end

  def points_profit_won
    points_invested_won - points_gain_won
  end

  def points_loss
    Bet.joins(:game_team).where("user_id = ? AND game_teams.result = ?", current_user.id, -1).sum("points")
  end

  def points_tie
    Bet.joins(:game_team).where("user_id = ? AND game_teams.result = ?", current_user.id, 0).sum("points")
  end

  def points_total_placed
    points_invested_won + points_loss + points_tie
  end

  def points_total_gained
    points_gain_won + points_tie
  end

  def point_total_profit
      points_profit_won - points_loss
  end

  def can_bet?(game)
    game.can_bet? && !game.users.include?(current_user)
  end
end

get '/' do
    redirect '/users/login'
end

get '/users/login' do
  erb :'users/login'
end

post '/users/login' do
  user = User.find_by(username: params[:username])
  if user.password_hash == params[:password_hash]
    session[:user_id] = user.id
    redirect '/users/login'
  else
    #TODO flash a message
    redirect "/users/login"
  end
end

#logout
get "/users/logout" do
  session.clear
  redirect "/users/login"
end
#user profile

get '/users/' do
  erb :'users/index'
end

# Charge with credit card
post '/charge' do
  Stripe.api_key = 'sk_test_yENZrfNUuVXFshfe9yOkatfu'
  StripeWrapper::Charge.create(
    card:        params[:stripeToken],
    amount:      2000,
    description: "BBettr user: #{current_user.email}"
  )
  current_user.points += 2000
  current_user.save!
  flash[:notice] = "You charged 2000 points into your account."
  redirect back
end

# Page: Show list of all games available for betting
get '/games' do
  i = 0
  @game_to_bet_on = []
  @games_array = []
  for i in 1..15
    @game_to_bet_on << { home_team: GameTeam.where(game_id: i).first.team.name, away_team: GameTeam.where(game_id: i).second.team.name, game_date: GameTeam.where(game_id: i).first.game.datetime, game_stadium_name: GameTeam.where(game_id: i).first.game.stadium.name, game_stadium_city: GameTeam.where(game_id: i).first.game.stadium.city
    }
    @games_array << Game.where(id: i).first
  end

  erb :'games/index'
end

# Page: Game details
get '/games/:id' do
  # binding.pry
  begin
    @game = Game.find(params[:id].to_i)
    @winning_team_name = @game.winner.team.name.upcase unless @game.tied?
    @city_name = @game.stadium.city.upcase
    erb :'games/show'
  rescue ActiveRecord::RecordNotFound => @e
    erb :'page_not_found'
  end
end
# Create a bet for a game
post '/games/:id/bets' do
  if params[:bet_points].to_i > get_points
    flash[:error] = "Sorry, you don't have enough points."
    redirect back
  end

  new_bet = Bet.new(points: params[:bet_points],
                    user: current_user,
                    game_team_id: params[:game_team_id])
  if new_bet.save
    flash[:notice] = 'You bet successfully.'
  else
    flash[:error] = 'Error happens when you bet.'
  end
  redirect back
end

# Page: My bets
get '/bets' do
  @completed_bets = []
  @upcoming_bets = []

  my_bets = Bet.all.where(user: current_user, archived: [false, nil])
  my_bets.each do |bet|
    if bet && bet.game && bet.game.completed?
      @completed_bets << bet
    else
      @upcoming_bets << bet
    end
  end

  erb :'bets/index'
end

# Archive a bet
patch '/bets/:id' do
  bet = Bet.find(params[:id])
  bet.archived = true
  bet.save
  redirect :'bets'
end

# Delete a bet
delete '/bets/:id' do
  bet = Bet.find(params[:id])
  if bet.destroy
    flash[:notice] = 'Your canceled a bet successfully.'
  else
    flash[:error] = 'Your bet cannot be deleted.'
  end
  redirect :'bets'
end

# Page: Leader board
get '/leaderboard' do
  @top_users = User.all.sort_by { |user| user.final_points }.reverse.take(10)
  erb :'users/leaderboard'
end

# Page: Custom Board

get '/customboard' do
  erb :'users/customboard'
end
