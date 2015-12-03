require '../lib/codebreaker'

TEST_ENV = {
  "rack.input"=> StringIO.new
}

RSpec.configure do |config|
  config.color = true
  config.tty = true
  config.formatter = :documentation
end