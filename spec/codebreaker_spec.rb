require_relative 'spec_helper'

describe Racker do
  let(:racker) { Racker.new(TEST_ENV) }

  context '#self' do
    it 'run :new, :response, :finish' do
      expect(Racker).to receive_message_chain(:new, :response, :finish)
      Racker.call(TEST_ENV)
    end
  end

  context '#new' do
    it '@request exist and be kind of Rack::Request' do
      request = racker.instance_variable_get(:@request)
      expect(request).to be_kind_of(Rack::Request)
    end
  end

  context '#response' do
    before { @request = racker.instance_variable_get(:@request) }
    after { racker.response }

    it 'when @request.path "/" run :welcome' do
      allow(@request).to receive(:path).and_return("/")
      expect(racker).to receive(:welcome)
    end

    it 'when @request.path "start_game" run :start_game' do
      allow(@request).to receive(:path).and_return("/start_game")
      expect(racker).to receive(:start_game)
    end

    it 'when @request.path "/game" run :game' do
      allow(@request).to receive(:path).and_return("/game")
      expect(racker).to receive(:game)
    end

    it 'when @request.path "/attempt" run :attempt' do
      allow(@request).to receive(:path).and_return("/attempt")
      expect(racker).to receive(:attempt)
    end

    it 'when @request.path "/hint" run :hint' do
      allow(@request).to receive(:path).and_return("/hint")
      expect(racker).to receive(:hint)
    end

    it 'when @request.path "/you_win" run :you_win' do
      allow(@request).to receive(:path).and_return("/you_win")
      expect(racker).to receive(:you_win)
    end

    it 'when @request.path "/you_lose" run :you_lose' do
      allow(@request).to receive(:path).and_return("/you_lose")
      expect(racker).to receive(:you_lose)
    end
  end

  context '#render' do
    it 'template "welcome.html.erb" contain "Welcome"' do
      expect(racker.render("welcome.html.erb")).to include("Welcome")
    end
  end

  context '#start_game' do
    before do
      allow(racker).to receive(:game_session).and_return(true)
      allow(racker).to receive(:cookie_player_name).and_return('ebony')
      allow(racker).to receive(:cookie_attempts_quantity).and_return('5')
    end

    it '@request session clear when game_session is true' do
      expect(racker.instance_variable_get(:@request).session).to receive(:clear)
      racker.start_game
    end

    it 'create @request.session[:game] when game_session is true' do
      racker.start_game
      game_session = racker.instance_variable_get(:@request).session[:game]
      expect(game_session.attempts_quantity).to eq 5
    end

    it 'create @request.session[:game] when game_session is false' do
      allow(racker).to receive(:game_session).and_return(false)
      allow(racker).to receive(:params_player_name).and_return('den')
      allow(racker).to receive(:params_attempts_quantity).and_return('10')
      racker.start_game
      game_session = racker.instance_variable_get(:@request).session[:game]
      expect(game_session.attempts_quantity).to eq 10
    end

    it 'exist empty hash [:result] in @request.session' do
      racker.start_game
      hash = racker.instance_variable_get(:@request).session[:result]
      expect(hash).to be_kind_of(Hash)
    end

    it 'redirect to "/game"' do
      action = racker.start_game
      expect(action.location).to eq '/game'
    end
  end

  context '#game' do
    it 'render game.html.erb' do
      allow(racker).to receive(:render).and_return("game.html.erb")
      expect(Rack::Response).to receive(:new).with(racker.render("game.html.erb"))
      racker.game
    end
  end

  context '#attempt' do
    before do
      allow(racker).to receive(:cookie_player_name).and_return('ebony')
      allow(racker).to receive(:cookie_attempts_quantity).and_return('5')
      racker.start_game
    end

    it 'answer to be false' do
      allow(racker).to receive(:params_player_code).and_return('')
      racker.attempt
      answer = racker.instance_variable_get(:@request).session[:result]
      expect(answer).to eq ({""=>false})
    end

    it 'not to be false' do
      allow(racker).to receive(:params_player_code).and_return('1111')
      racker.attempt
      answer = racker.instance_variable_get(:@request).session[:result]["1111"]
      expect(answer).not_to be_falsey
    end

    it 'if game victory, run :save_to_hall_of_fame' do
      allow(racker.game_session).to receive(:victory?).and_return(true)
      expect(racker).to receive(:save_to_hall_of_fame)
      racker.attempt
    end

    it 'redirect to "/you_win"' do
      allow(racker.game_session).to receive(:victory?).and_return(true)
      allow(racker).to receive(:save_to_hall_of_fame).and_return(true)
      action = racker.attempt
      expect(action.location).to eq "/you_win"
    end

    it 'redirect to "/you_win"' do
      allow(racker.game_session).to receive(:lose?).and_return(true)
      action = racker.attempt
      expect(action.location).to eq "/you_lose"
    end

    it 'redirect to "/you_win"' do
      allow(racker.game_session).to receive(:victory?).and_return(false)
      allow(racker.game_session).to receive(:lose?).and_return(false)
      action = racker.attempt
      expect(action.location).to eq "/game"
    end
  end

  context '#hint' do
    before { racker.start_game }

    it 'set cookie hint' do
      allow(racker.game_session).to receive(:check_hint).and_return('***2')
      action = racker.hint
      expect(action["Set-Cookie"]).to eq "hint=***2"
    end

    it 'redirect to "/game"' do
      action = racker.hint
      expect(action.location).to eq '/game'
    end
  end

  context '#welcome' do
    it 'request clear session' do
      request_session = racker.instance_variable_get(:@request).session
      expect(request_session).to receive(:clear)
      racker.welcome
    end

    it 'render "welcome.html.erb"' do
      expect(Rack::Response).to receive(:new).with(racker.render("welcome.html.erb"))
      racker.welcome
    end
  end

  context '#you_win' do
    before { allow(racker).to receive(:render).and_return("you_win.html.erb") }

    it 'YAML run :load_documents' do
      allow(File).to receive(:open).and_return("hall_of_fame.txt")
      expect(YAML).to receive(:load_documents).with("hall_of_fame.txt")
      racker.you_win
    end

    it 'render "you_win.html.erb"' do
      expect(Rack::Response).to receive(:new).with(racker.render("you_win.html.erb"))
      racker.you_win
    end
  end

  context '#you_lose' do
    it 'render you_lose.html.erb' do
      allow(racker).to receive(:render).and_return("you_lose.html.erb")
      expect(Rack::Response).to receive(:new).with(racker.render("you_lose.html.erb"))
      racker.you_lose
    end
  end

  context '#save_to_hall_of_fame' do
    before { racker.start_game }

    it 'exist file hall_of_fame.txt' do
      allow(racker).to receive(:cookie_player_name).and_return('ebony')
      allow(racker.game_session).to receive(:count).and_return(10)
      allow(racker.game_session).to receive(:player_arr).and_return([1,1,1,1])
      expect(File.exist?("./database/hall_of_fame.txt")).to eq true
      racker.save_to_hall_of_fame
    end
  end

  context '#params_player_code' do
    it 'return "1111" from @request.params["player_code"]' do
      request = racker.instance_variable_get(:@request)
      allow(request).to receive(:params).and_return({"player_code"=>"1111"})
      expect(racker.params_player_code).to eq "1111"
    end
  end

  context '#params_player_name' do
    it 'return "ebony" from @request.params["player_name"]' do
      request = racker.instance_variable_get(:@request)
      allow(request).to receive(:params).and_return({"player_name"=>"ebony"})
      expect(racker.params_player_name).to eq "ebony"
    end
  end

  context '#params_attempts_quantity' do
    it 'return "10" from @request.params["attempts_quantity"]' do
      request = racker.instance_variable_get(:@request)
      allow(request).to receive(:params).and_return({"attempts_quantity"=>"10"})
      expect(racker.params_attempts_quantity).to eq "10"
    end
  end

  context '#cookie_player_name' do
    it 'return "ebony" from @request.cookie["player_name"]' do
      request = racker.instance_variable_get(:@request)
      allow(request).to receive(:cookies).and_return({"player_name"=>"ebony"})
      expect(racker.cookie_player_name).to eq "ebony"
    end
  end

  context '#cookie_attempts_quantity' do
    it 'return "10" from @request.cookie["attempts_quantity"]' do
      request = racker.instance_variable_get(:@request)
      allow(request).to receive(:cookies).and_return({"attempts_quantity"=>"10"})
      expect(racker.cookie_attempts_quantity).to eq "10"
    end
  end

  context '#cookie_hint' do
    before { @request = racker.instance_variable_get(:@request) }

    it 'return "" if @request.cookies["hint"] has "false"' do
      allow(@request).to receive(:cookies).and_return({"hint"=>"false"})
      expect(racker.cookie_hint).to eq ""
    end

    it '@request.cookies["hint"] return "***2"' do
      allow(@request).to receive(:cookies).and_return({"hint"=>"***2"})
      expect(racker.cookie_hint).to eq "***2"
    end
  end

  context '#game_session' do
    it 'not to be nil' do
      racker.start_game
      expect(racker.game_session).not_to be_nil
    end
  end

end