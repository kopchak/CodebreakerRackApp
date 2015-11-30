require_relative 'spec_helper'

describe Racker do



  context '#self' do
    it 'self call to :new, :response and finish' do
      expect(Racker).to receive_message_chain(:new, :response, :finish)
      Racker.call('env')
    end
  end

  context '#new' do
  end

  context '#response' do
    before { @request = Rack::Request.new('env') }

    it 'bla' do
      @request.stub(:path).and_return('/')
      expect(Racker.response).to receive(:welcome).with(no_args())
    end
  end

  context '#render' do
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