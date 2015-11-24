require "erb"
require 'bundler/setup'
require "codebreaker"

class Racker
  def self.call(env)
    new(env).response.finish
  end
   
  def initialize(env)
    @request = Rack::Request.new(env)
  end
   
  def response
    case @request.path
    when "/" then Rack::Response.new(render("welcome.html.erb"))
    when "/index" then Rack::Response.new(render("index.html.erb"))
    # when "/you_win" then Rack::Response.new(render("you_win.html.erb"))
    # when "/you_lose" then Rack::Response.new(render("you_lose.html.erb"))

    when "/start_game"
      create_game
      Rack::Response.new do |response|
        response.set_cookie("player_name", @request.params["player_name"])
        response.set_cookie("result", '')
        response.set_cookie("player_code", '')
        response.set_cookie("hint", '')
        response.redirect("/index")
      end

    when "/game"
      if  @@game.victory?
        Rack::Response.new(render("you_win.html.erb"))
        
      elsif @@game.attempts_quantity > 1
        # p '11'
        Rack::Response.new do |response|
          response.set_cookie("player_code", @request.params["player_code"])
          response.set_cookie("result", @@game.guess(@request.params["player_code"]))
          response.redirect("/index")
        end
      else
        Rack::Response.new(render("you_lose.html.erb"))
      end

    when "/hint"

      Rack::Response.new do |response|
        response.set_cookie("hint", @@game.check_hint)
        response.redirect("/index")
      end

    else Rack::Response.new("Not Found", 404)
    end
  end
   
  def render(template)
    path = File.expand_path("../../views/#{template}", __FILE__)
    ERB.new(File.read(path)).result(binding)
  end

  def create_game
    @@game = Codebreaker::Game.new(@request.params["player_name"], @request.params["attempts_quantity"].to_i)
  end

  def display_result
    result = @request.cookies["result"]
    if result == 'false'
      result = 'Invalid data'
    else
      result
    end
  end

  def display_name
    @request.cookies["player_name"]
  end

  def display_attempts_quantity
    @@game.attempts_quantity
  end

  def display_player_code
    @request.cookies["player_code"]
  end

  def display_hint
    result = @request.cookies["hint"]
    if result == 'false'
      result = 'Number of hints ended'
    else
      result
    end
  end

end