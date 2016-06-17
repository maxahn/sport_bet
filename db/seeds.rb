class AddInitialUsers < ActiveRecord::Migration

  user_names = ["Richard", "Natalia", "Ben", "Max", "Matt", "Eamonn", "Vanessa", "Deepak", "Alexandra","Juliana", "Terrance"]
  bet_points = [1500, 1500, 1500, 150000000, 200, 300, 1, 500, 600, 0, 2000]
  
  email = "@sports_bet.com"
  i = 0 
  user_names.each do |name|
    User.create!(username: name, password_hash: 'password', email: name + email, points: bet_points[i])  
    i += 1
  end
  
  #Following.create!(follower:1, followee: 2)

end