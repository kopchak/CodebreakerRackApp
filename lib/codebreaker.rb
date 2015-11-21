require "erb"
# require_relative 'game'

class Codebreaker
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
    when "/you_lose" then Rack::Response.new(render("you_lose.html.erb"))

    when "/set_name"
      Rack::Response.new do |response|
        response.set_cookie("player_name", @request.params["player_name"])
        response.set_cookie("player_code", '')
        response.set_cookie("secret_code", generate_secret_code_str)
        response.set_cookie("hint_quantity", 1)
        response.set_cookie("hint", '')
        response.set_cookie("attempt_quantity", 1)
        response.redirect("/index")
      end

    when "/get_player_input"
      Rack::Response.new do |response|
        response.set_cookie("player_code", @request.params["player_code"])
        response.set_cookie("attempt_quantity", attempt_quantity!)
        response.redirect("/index")
      end

    when "/get_hint"
      Rack::Response.new do |response|
          response.set_cookie("hint", get_hint)
          response.set_cookie("hint_quantity", 0)
          response.redirect("/index")
      end

    else Rack::Response.new("Not Found", 404)
    end
  end
   
  def render(template)
    path = File.expand_path("../views/#{template}", __FILE__)
    ERB.new(File.read(path)).result(binding)
  end

  def player_name
    @player_name = @request.cookies["player_name"].capitalize
  end

  def get_player_input
    player_code = @request.cookies["player_code"]
    player_code = /[1-6]{4}/.match(player_code).to_s
    @player_code_arr = player_code.split('').map(&:to_i)
    player_code
  end

  def compare_of_value(player_arr)
    secret_arr = Array.new(@secret_arr)
    player_arr = Array.new(player_arr)
    result_str = ''
    player_arr.each_index do |i|
      if player_arr[i] == secret_arr[i]
        result_str += '+'
        secret_arr[i] = 0
        player_arr[i] = nil
      end
    end
    player_arr.each_index do |i|
      if secret_arr.include?(player_arr[i])
        result_str += '-'
        index = secret_arr.find_index(player_arr[i])
        secret_arr[index] = 0
      end
    end
    result_str
  end

  def display_compare_of_value
    result = compare_of_value(@player_code_arr)
    result
  end

  def generate_secret_code_str
    secret_code_str = ''
    4.times { |i| secret_code_str << rand(1..6).to_s }
    secret_code_str
  end

  def get_secret_code_to_arr
    secret_code_str = @request.cookies["secret_code"]
    @secret_arr = secret_code_str.split('').map(&:to_i)
  end

  def display_hint_quantity
    @request.cookies["hint_quantity"]
  end

  def random_num
    @random = rand(0..3)
  end

  def get_hint
    hint_quantity = @request.cookies["hint_quantity"].to_i
    if hint_quantity == 1
      get_secret_code_to_arr
      random_num
      result = "****"
      result[@random] = @secret_arr[@random].to_s
    else
      result = 'number of hints ended'
    end
    result
  end

  def display_hint
    @request.cookies["hint"] || '****'
  end

  def attempt_quantity!
    attempt_quantity = @request.cookies["attempt_quantity"].to_i
    attempt = attempt_quantity + 1
  end

  def display_attempt_quantity
    @request.cookies["attempt_quantity"]
  end

  def you_lose
    attempt_quantity = @request.cookies["attempt_quantity"].to_i
    if attempt_quantity == 10
      # Rack::Request.new(redirect("/you_lose"))
      # Rack::Response.new(redirect("/you_lose"))
    end
  end

  def you_win
    
  end

  # def check_input
    # if @request.cookies["player_code"] == 'hint'
    #   @hint -= 1
      # get_hint
    # elsif @player_code == 'hint' && @hint == 0
    #   p "#{@player_name} you have used a hint!"
    # else
    #   select_only_digits!
    #   player_input_to_arr!
    # end
  # end

end