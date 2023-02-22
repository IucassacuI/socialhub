require 'pstore'
require 'bcrypt'
require 'open-uri'
require 'json'

$users = PStore.new 'users'
$cache = PStore.new 'cache'

def exist(user)
  !$users.transaction(true) { $users[user] }.nil?
end

def login(user, pass)
  return ['/err?code=1', false] unless exist(user)

  dbpass = BCrypt::Password.new $users.transaction(true) { $users[user][:pass] }

  return ["/user/#{user}", true] if dbpass == pass

  ['/err?code=2', false]
end

def signup(user, pass)
  supass = BCrypt::Password.create(pass).to_s

  $users.transaction { $users[user] = { pass: supass, insta: [], twit: [], yt: [], red: [] } }
  $cache.transaction { $cache[user] = { insta: [], twit: [], yt: [], red: [] } }
end

def follows(user, net)
  $users.transaction(true) { $users[user][net] }
end

def update(user)
  nets = {
    'instagram' => [method(:iusers), :insta],
    'twitter' => [method(:tusers), :twit],
    'youtube' => [method(:yusers), :yt],
    'reddit' => [method(:rsubs), :red]
  }

  nets.each_pair do |net, methodsym|
    method = methodsym[0]

    method.call(user).each do |u|
      posts = URI.open(URI("http://localhost:4567/#{net}/#{u}?truncate=1")).read

      $cache.transaction do
        sym = methodsym[1]

        cache = $cache[user][sym]
        json = JSON.parse(posts)

        $cache[user][sym].pop if $cache[user][sym].size > 5
        $cache[user][sym] = [json] + $cache[user][sym] unless cache.include? json
      end
    end
  end
end

def change(user, instagram, twitter, reddit, yt)
  $users.transaction do
    $users[user][:insta] = instagram.split
    $users[user][:twit] = twitter.split
    $users[user][:red] = reddit.split
    $users[user][:yt] = yt.split
  end
end

def cache(user)
  f = {}

  usercache = $cache.transaction { $cache[user] }

  usercache.each_pair do |net, posts|
    f[net.to_s] = posts
  end

  f
end

def account(user, newpass)
  bpass = BCrypt::Password.create(newpass).to_s
  $users.transaction { $users[user][:pass] = bpass }
end
