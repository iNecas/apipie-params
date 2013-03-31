if ENV['SIMPLECOV']
  require 'simplecov'
  SimpleCov.start do
    add_filter '/test/'
  end
end

require 'test/unit'


require 'minitest/spec'

require 'apipie-params'
