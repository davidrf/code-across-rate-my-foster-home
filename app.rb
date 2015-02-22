require 'sinatra'
require 'sinatra/reloader'
require 'csv'
require 'date'
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
  CSV.open("homes.csv", "a") do |csv|
    csv << [user, info[:home]]
  end
end

def get_reviews(home)
  homes = []
  CSV.foreach("reviews.csv", headers: true, header_converters: :symbol) do |row|
    reviews_hash = row.to_hash
    homes << reviews_hash if reviews_hash[:home] == home
  end
  homes.reverse
end

def store_review(review)
  date = Time.now.to_s
  date = DateTime.parse(date).strftime("%d/%m/%Y %H:%M")

  CSV.open("reviews.csv", "a") do |csv|
    csv << [review[:home], review[:reviewer], date, review[:rating], review[:explanation]]
  end
end

def go_up_directory(path)
  path = path.split("/")
  path.pop
  path.join("/")
end

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
  if params[:add]
    add_home(session[:user], params)
  else
    delete(params["home"])
  end

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

get '/foster_homes/new_review/:home' do |home|
  @home = home
  erb :review_options
end

get '/foster_homes/new_review/:home/:person' do |home, person|
  @home = home

  if person == "parents"
    erb :parent_review
  elsif person == "children"
    erb :children_review
  else
    erb :worker_review
  end
end

post '/foster_homes/new_review/:home/:person' do |home, person|
  store_review(params)
  path = go_up_directory(request.path)
  redirect(path)
end
