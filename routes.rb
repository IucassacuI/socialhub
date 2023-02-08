require 'sinatra'
require_relative 'sh.rb'

configure do
  enable :sessions
  set :port, 80
end

$sessions = {}

get '/' do
  if !session['sess'].nil?
    user = $sessions[session['sess']]
    redirect "/user/#{user}"
  else
    erb :login
  end
end

post '/login' do
  user = params['user']
  pass = params['pass']
  
  redir, success = login(user, pass)
  
  if success
    update(user)
    session['sess'] = SecureRandom.hex 10
    $sessions[session['sess']] = user
  end

  redirect redir
end

post '/new' do
  user = params['user']
  pass = params['pass']
  signup(user, pass)

  redirect '/'
end

get '/signup' do
  haml :signup
end

post '/follow/:platform' do |platform|
  users = params['users']
  user = $sessions[session['sess']]

  change platform, user, users
  update user
  haml :config, locals: {saved: true, insta: iusers(user), twit: tusers(user), yt: yusers(user)}
end

get '/user/*' do
  profile = params['splat'][0]
  c = cache(profile)
    
  haml :main, locals: {user: profile, cache: c}
end

get '/logout' do
  $sessions.delete session['sess']
  session.delete 'sess'
  redirect '/'
end

get '/config' do
  user = $sessions[session['sess']]
  haml :config, locals: {yt: yusers(user), insta: iusers(user), twit: tusers(user), user: user}
end

post '/account' do
  user = $sessions[session['sess']]

  account user, params['pass']

  redirect "/user/#{user}"
end
