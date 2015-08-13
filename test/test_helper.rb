require 'minitest/autorun'
if ENV['SIMPLECOV']
  require 'simplecov'
  SimpleCov.start do
    add_filter '/test/'
  end
end

require 'minitest/spec'

require 'apipie-params'
