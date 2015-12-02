require 'erb'
require 'yaml'
require 'rack'
require 'codebreaker'

class Racker
  def self.call(env)
    new(env).response.finish
  end
   
  def initialize(env)
    @request = Rack::Request.new(env)
  end
   
  def response
    case @request.path
    when '/'           then welcome
    when '/start_game' then start_game
    when "/game"       then game
    when "/attempt"    then attempt
    when "/hint"       then hint
    when "/you_win"    then you_win
    when "/you_lose"   then you_lose
    else Rack::Response.new("Not Found", 404)
    end
  end
   
  def render(template)
    path = File.expand_path("../views/#{template}", __FILE__)
    ERB.new(File.read(path)).result(binding)
  end

  def start_game
    Rack::Response.new do |response|
      response.delete_cookie("hint")
      if game_session
        @request.session.clear
        @request.session[:game] = Codebreaker::Game.new(cookie_player_name, cookie_attempts_quantity.to_i)
      else
        response.set_cookie("player_name", params_player_name)
        response.set_cookie("attempts_quantity", params_attempts_quantity)
        @request.session[:game] = Codebreaker::Game.new(params_player_name, params_attempts_quantity.to_i)
      end
      @request.session[:result] = {}
      response.redirect("/game")
    end
  end

  def game
    if cookie_player_name.empty? && cookie_attempts_quantity.empty?
      Rack::Response.new { |response| response.redirect("/") }
    else
      Rack::Response.new(render("game.html.erb"))
    end
  end

  def attempt
    answer = game_session.guess(params_player_code)
    @request.session[:result][params_player_code] = answer
    p @request.session
    if game_session.victory?
      save_to_hall_of_fame
      Rack::Response.new { |response| response.redirect("/you_win") }
    elsif game_session.lose?
      Rack::Response.new { |response| response.redirect("/you_lose") }
    else
      Rack::Response.new { |response| response.redirect("/game") }
    end
  end

  def hint
    Rack::Response.new do |response|
      response.set_cookie("hint", game_session.check_hint)
      response.redirect("/game")
    end
  end

  def welcome
    @request.session.clear
    Rack::Response.new(render('welcome.html.erb'))
  end

  def you_win
    @hall_of_fame = YAML.load_documents(File.open("./database/hall_of_fame.txt"))
    Rack::Response.new(render("you_win.html.erb"))
  end

  def you_lose
    Rack::Response.new(render("you_lose.html.erb"))
  end

  def save_to_hall_of_fame
    winner = {
      name: cookie_player_name,
      attempts_count: game_session.count,
      secret_code: game_session.player_arr.join
    }
    File.open("./database/hall_of_fame.txt", 'a') { |file|  file.write(YAML.dump(winner)) }
  end

  def params_player_code
    @request.params["player_code"]
  end

  def params_player_name
    @request.params["player_name"]
  end

  def params_attempts_quantity
    @request.params["attempts_quantity"]
  end

  def cookie_player_name
    @request.cookies["player_name"]
  end

  def cookie_attempts_quantity
    @request.cookies["attempts_quantity"]
  end

  def display_hint
    @request.cookies["hint"] || ""
  end

  def game_session
    @request.session[:game]
  end

end