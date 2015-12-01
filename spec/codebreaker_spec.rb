require_relative 'spec_helper'

describe Racker do
  include Rack::Test::Methods
  let(:racker) { Racker.new(TEST_ENV) }

  context '#self' do
    it 'call to :new, :response and finish' do
      expect(Racker).to receive_message_chain(:new, :response, :finish)
      Racker.call('env')
    end
  end

  context '#new' do
  end

  # context '#response' do

  #   it 'bla' do
  #     request = double('request', path: '/bla')
  #     allow(Rack::Request).to receive(:new).and_return(@request)
  #     expect(Racker).to receive(:welcome)
  #     Racker.call('env')
  #     # Racker.response
  #   end
  # end

  context '#render' do
    it 'bla' do
      expect(racker.render('welcome.html.erb')).to eq 1
    end
  end

  context '#start_game' do
  end

  context '#game' do
  end

  context '#attempt' do
  end

  context '#you_win' do
  end

  context '#save_to_hall_of_fame' do
  end

  context '#create_session' do
  end

  context '#update_session' do
  end

  context '#load_session' do
  end

  context '#display_name' do
  end

  context '#display_hint' do
  end

end