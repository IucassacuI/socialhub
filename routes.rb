require 'sinatra'
require_relative 'sh'

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

post '/update' do
  insta = params['insta']
  twit = params['twit']
  reddit = params['red']
  yt = params['yt']

  user = $sessions[session['sess']]

  halt 401 if user.nil?

  change user, insta, twit, reddit, yt
  update user
  redirect '/config?saved=1'
end

get '/user/*' do
  profile = params['splat'][0]

  halt 404 unless exist(profile)

  c = cache(profile)

  haml :main, locals: { user: profile, cache: c }
end

get '/logout' do
  $sessions.delete session['sess']
  session.delete 'sess'
  redirect '/'
end

get '/config' do
  user = $sessions[session['sess']]

  halt 401 if user.nil?

  saved = !params['saved'].nil?

  haml :config,
       locals: { saved: saved,
                 yt: follows(user, :yt),
                 insta: follows(user, :insta),
                 twit: follows(user, :twit),
                 red: follows(user, :red),
                 user: user
               }
end

post '/account' do
  user = $sessions[session['sess']]

  account user, params['pass']

  redirect "/user/#{user}"
end
