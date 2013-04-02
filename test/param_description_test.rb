require 'test_helper'
require 'forwardable'

class ParamDescriptionTest < Test::Unit::TestCase

  # TODO: would be nice if it was BasicObject so that we don't have
  # the kernel methods polution
  class MessageData

  end

  class TestClass
    extend Forwardable

    def initialize(data = {})
      @data = data
      build_message
      build_delegators
    end

    def format
      @format ||= Apipie::Params::Description.define do
        param :name,    String
        param :age,     Integer
        param :address, Hash do
          param :street, String
          param :zip,    String
        end
      end
    end

    def build_message
      @message_data = build_message_data(format, @data)
    end

    def build_delegators
      format.params.each do |param_description|
        singleton_class.send(:def_delegator, :@message_data, param_description.name)
      end
    end

    def build_message_data(param_description, data)
      message_data = MessageData.new
      param_description.params.each do |subparam_description|
        value = data[subparam_description.name]
        add_param(message_data, subparam_description, value)
      end
      return message_data
    end

    def add_param(message_data, param_description, value)
      if(param_description.descriptor.is_a? Apipie::Params::Descriptor::Array)
        if value
          attr_value = value.map do |attr_data|
            build_attr_value(param_description, value)
          end
        else
          attr_value = []
        end
      else
        attr_value = build_attr_value(param_description, value)
      end
      singleton_class = message_data.instance_eval('class << self; self; end')
      singleton_class.send(:attr_accessor, param_description.name)
      message_data.send("#{param_description.name}=", attr_value)
    end

    def build_attr_value(param_description, value)
      if param_description.respond_to? :params
        build_message_data(param_description, value)
      else
        value
      end
    end

  end

  def test_param_description
    test_data = {
      :name => 'Peter Smith',
      :age => 38,
      :address => { :street => "Baker's street'", :zip => '007' }
    }

    test = TestClass.new(test_data)
    assert_equal 'Peter Smith', test.name
    assert_equal '007', test.address.zip
  end
end
