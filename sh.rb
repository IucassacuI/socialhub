require 'pstore'
require 'bcrypt'
require 'open-uri'
require 'json'

$users = PStore.new 'users'
$cache = PStore.new 'cache'

def exist user
  !$users.transaction(true){$users[user]}.nil?
end

def login user, pass
  
  unless exist(user)
    return ['/err?code=1', false]
  end

  dbpass = BCrypt::Password.new $users.transaction(true) {$users[user][:pass]}
  
  if dbpass == pass
    return  ["/user/#{user}", true]
  else
    return ['/err?code=2', false]
  end
end

def signup user, pass
  supass = BCrypt::Password.create(pass).to_s
  
  $users.transaction{$users[user] = {pass: supass, insta: [], twit: [], yt: []}}
  $cache.transaction{$cache[user] = {insta: [], twit: [], yt: []}}
end

def iusers user
  $users.transaction(true){$users[user][:insta]}
end

def tusers user
  $users.transaction(true){$users[user][:twit]}
end

def yusers user
  $users.transaction(true){$users[user][:yt]}
end

def update user

  tusers(user).each do |u|
    posts = URI.open(URI("http://localhost:4567/twitter/#{u}?truncate=1")).read

    $cache.transaction do
      tcache = $cache[user][:twit]
      json = JSON.parse(posts)
      
      $cache[user][:twit].push json unless tcache.include? json
    end
  end

  iusers(user).each do |u|
    posts = URI.open(URI("http://localhost:4567/instagram/#{u}?truncate=1")).read

    $cache.transaction do
      icache =  $cache[user][:insta]
      json = JSON.parse(posts)
      
      $cache[user][:insta].push json unless icache.include? json
    end
  end

  yusers(user).each do |u|
    posts = URI.open(URI("http://localhost:4567/youtube/#{u}?truncate=1")).read

    $cache.transaction do
      ycache = $cache[user][:yt]
      json = JSON.parse(posts)
      
      $cache[user][:yt].push json unless ycache.include? json
    end
  end
end

def change platform, user, users
  $users.transaction{$users[user][platform.to_sym] = users.split}
end

def cache user
  f = {}

  usercache = $cache.transaction{$cache[user]}

  usercache.each_pair do |net, posts|
    f[net.to_s] = posts
  end

  f
end

def account user, newpass
  bpass = BCrypt::Password.create(newpass).to_s
  $users.transaction {$users[user][:pass] = bpass}
end