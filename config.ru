require "./lib/codebreaker_rack"
use Rack::Static, :urls => ["/stylesheets"], :root => "public"
use Rack::Session::Cookie, :key => 'rack.session',
                           :path => '/',
                           :expire_after => 2592000,
                           :secret => 'change_me',
                           :old_secret => 'also_change_me'
run Racker