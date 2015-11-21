require "./lib/codebreaker"
use Rack::Static, :urls => ["/stylesheets"], :root => "public"
run Codebreaker