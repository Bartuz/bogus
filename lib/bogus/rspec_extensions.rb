module Bogus
  module RSpecExtensions
    def fake(name, opts = {}, &block)
      let(name) { Bogus.fake_for(name, opts, &block) }
    end

    def verify_contract(name)
      before do
        Bogus.record_calls_for(name)
      end

      RSpec.configure do |config|
        config.after(:suite) { Bogus.verify_contract!(name) }
      end
    end
  end
end

