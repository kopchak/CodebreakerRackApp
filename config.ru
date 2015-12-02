require "./lib/codebreaker"
use Rack::Session::Cookie, :key => 'rack.session',
                           :path => '/',
                           :expire_after => 2592000,
                           :secret => 'change_me',
                           :old_secret => 'also_change_me'
use Rack::Static, :urls => ["/stylesheets"], :root => "public"
run Racker