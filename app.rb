require 'sinatra'
require 'sinatra/reloader'
require 'csv'
enable :sessions

configure :development, :test do
  require 'pry'
end

Dir[File.join(File.dirname(__FILE__), 'lib', '**', '*.rb')].each do |file|
  require file
  also_reload file
end

def valid_sign_in?(input)
  return false if input.values.include?("")

  username = input[:username]
  password = input[:password]
  user_info = retrieve_user_info(username)

  user_info[:username] == username && user_info[:password] == password
end

def retrieve_user_info(username)
  users = {}
  CSV.foreach("users.csv", headers: true, header_converters: :symbol) do |row|
    user_hash = row.to_hash
    users = user_hash  if user_hash[:username] == username
  end
  users
end

def retrieve_homes_for(user)
  homes = []
  CSV.foreach("homes.csv", headers: true, header_converters: :symbol) do |row|
    homes_hash = row.to_hash
    homes << homes_hash[:home] if homes_hash[:user] == user
  end
  homes
end

def delete(home)
  table = CSV.table('homes.csv')

  table.delete_if do |row|
    row[:home] == home
  end

  File.open('homes.csv', 'w') do |f|
    f.write(table.to_csv)
  end
end

def add_home(user, info)
  #Still working on this - DRF 2/22/15 8:14 AM
  binding.pry
  File.open('homes.csv', 'a') do |f|
    f.write("#{user},#{info["home"]}")
  end

  home = info.delete("home")
  info =

  File.open('people.csv', 'a') do |f|
    f.write("#{home},#{info.values.joi}")
  end
end

def get_reviews(home)
  homes = []
  CSV.foreach("reviews.csv", headers: true, header_converters: :symbol) do |row|
    reviews_hash = row.to_hash
    homes << reviews_hash if reviews_hash[:home] == home
  end
  homes
end
#
# def get_first_person(home, person_type)
# end
#
# def get_next_person(person, person_type)
# end
#
# def store_review(reviewer, review)
# end

get '/' do
  redirect('/sign_in')
end

get '/sign_in' do
  @input = Hash.new("")
  erb :sign_in
end

post '/sign_in' do
  if valid_sign_in?(params)
    session[:user] = params[:username]
    redirect('/foster_homes')
  else
    @input = params
    erb :sign_in
  end
end

get '/foster_homes' do
  @homes = retrieve_homes_for(session[:user])
  erb :foster_homes
end

post '/foster_homes' do
  delete(params["home"])
  redirect('/foster_homes')
end

get '/new_home' do
  @input = Hash.new("")
  erb :new_home
end

post '/new_home' do
  add_home(session[:user], params)
  redirect('/foster_homes')
end

get '/foster_homes/reviews/:home' do |home|
  @reviews = get_reviews(home)
  erb :home_reviews
end
#
# get '/foster_homes/new_review/:home' do |home|
#   @parent = get_first_person(home, "parent")
#   redirect("/foster_homes/new_review/:home/parents/#{@parent}")
# end
#
# get '/foster_homes/new_review/:home/parents/:parent' do |home, parent|
#   @home = home
#   @parent = parent
#   erb :rate_page
# end
#
# post '/foster_homes/new_review/:home/parents/:parent' do |home, parent|
#   store_review(home, parent, params)
#   @parent = get_next_person(parent, "parent")
#   if @parent
#     redirect("/foster_homes/new_review/:home/parents/#{@parent}")
#   else
#     @kid = get_first_person(home, "kid")
#     redirect("/foster_homes/new_review/:home/kids/#{@kid}")
#   end
# end
#
# get '/foster_homes/new_review/:home/kids/:kid' do |home, kid|
#   @home = home
#   @kid = kid
#   erb :rate_page
# end
#
# post '/foster_homes/new_review/:home/kids/:kid' do |home, kid|
#   store_review(home, kid, params)
#   @kid = get_next_person(kid)
#   if @kid
#     redirect("/foster_homes/new_review/:home/kids/#{@kid}")
#   else
#     redirect("/foster_homes/new_review/:home/#{session[:user]}")
#   end
# end
#
# get '/foster_homes/new_review/:home/:user' do |home, user|
#   @home = home
#   @user = user
#   erb :rate_page
# end
#
# post '/foster_homes/new_review/:home/:user' do |home, user|
#   store_review(home, user, params)
#   redirect('/foster_homes')
# end
