require 'erb'
require 'yaml'
require 'rack'
require 'bundler/setup'
require 'codebreaker'

class Racker
  def self.call(env)
    new(env).response.finish
  end
   
  def initialize(env)
    @request = Rack::Request.new(env)
    @game = Codebreaker::Game.new(@request.params["player_name"], @request.params["attempts_quantity"].to_i)
    @player_id = @request.cookies["player_id"]
    @player_code = @request.params["player_code"]
  end
   
  def response
    case @request.path
    when '/' then welcome
    when '/start_game' then start_game
    when "/game" then game
    when "/attempt" then attempt
    when "/hint" then hint
    when "/you_win" then you_win
    else Rack::Response.new("Not Found", 404)
    end
  end
   
  def render(template)
    path = File.expand_path("../views/#{template}", __FILE__)
    ERB.new(File.read(path)).result(binding)
  end

  def welcome
    Rack::Response.new(render('welcome.html.erb'))
  end

  def start_game
    create_session
    Rack::Response.new do |response|
      response.set_cookie("player_name", @request.params["player_name"])
      response.set_cookie("player_id", @player_id)
      response.delete_cookie("hint")
      response.redirect("/game")
    end
  end

  def game
    if @player_id
      load_session(@player_id)
      Rack::Response.new(render("game.html.erb"))
    else
      Rack::Response.new { |response| response.redirect("/") }
    end
  end

  def attempt
    load_session(@player_id)
    @result = @game.guess(@player_code)
    update_session(@player_id)
    if @game.victory?
      save_to_hall_of_fame
      Rack::Response.new { |response| response.redirect("/you_win") }
    elsif @game.lose?
      Rack::Response.new(render("you_lose.html.erb"))
    else
      Rack::Response.new { |response| response.redirect("/game") }
    end
  end

  def hint
    load_session(@player_id)
    Rack::Response.new do |response|
      response.set_cookie("hint", @session_info[0][:hint])
      response.redirect("/game")
    end
  end

  def you_win
    @hall_of_fame = File.readlines("./database/hall_of_fame.txt")
    Rack::Response.new(render("you_win.html.erb"))
  end

  def save_to_hall_of_fame
    winner = "Player name: #{@session_info[0][:player_name]},
              has been spent attempts: #{@session_info[0][:count]},
              secret code: #{@session_info[0][:secret_arr].join}"
    File.open("./database/hall_of_fame.txt", 'a') { |file|  file.puts winner.tr("\n", ' ') }
  end

  def create_session
    @player_id = @game.object_id
    session = [
      player_name: @game.instance_variable_get(:@player_name),
      attempts_quantity: @game.attempts_quantity,
      hint: @game.check_hint,
      count: @game.count,
      secret_arr: @game.instance_variable_get(:@secret_arr),
    ]
    File.open("./database/#{@player_id}.txt", "w") { |file| file.write(YAML.dump(session)) }
  end

  def update_session(player_id)
    @session_info[0][:attempts_quantity] = @game.attempts_quantity
    @session_info[0][:count] = @game.count
    @session_info << [@result, @player_code]
    File.open("./database/#{player_id}.txt", "w") { |file| file.write(YAML.dump(@session_info)) }
  end

  def load_session(player_id)
    @session_info = YAML.load(File.open("./database/#{player_id}.txt"))
    @game.instance_variable_set(:@player_name, @session_info[0][:player_name])
    @game.instance_variable_set(:@attempts_quantity, @session_info[0][:attempts_quantity])
    @game.instance_variable_set(:@hint_quantity, @session_info[0][:hint_quantity])
    @game.instance_variable_set(:@hint, @session_info[0][:hint])
    @game.instance_variable_set(:@count, @session_info[0][:count])
    @game.instance_variable_set(:@secret_arr, @session_info[0][:secret_arr])
  end

  def display_name
    @request.cookies["player_name"]
  end

  def display_hint
    @request.cookies["hint"]
  end

end