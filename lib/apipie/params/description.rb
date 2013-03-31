require 'forwardable'

module Apipie
  module Params
    class Description

      attr_accessor :name, :desc, :allow_nil, :required, :descriptor, :options

      def self.define(&block)
        param_description = Description.new(nil, nil, {})
        param_description.descriptor =
          Descriptor::Hash.new(param_description, block, {})
        return param_description
      end

      def initialize(name, descriptor_arg, options = {}, &block)
        @options = options
        @name = name
        @desc = @options[:desc]
        # if required is specified, set to boolean of the value, nil
        # otherwise: nil allows us specify the default value later.
        @required = @options.has_key?(:required) ? !!@options[:required] : nil
        @allow_nil = @options.has_key?(:allow_nil) ? !!@options[:allow_nil] : nil

        unless descriptor_arg.nil?
          @descriptor = Params::Descriptor::Base.find(self,
                                                      descriptor_arg,
                                                      options,
                                                      block)
        else
          @descriptor = nil
        end

      end

      def respond_to?(method)
        case method.to_s
        when 'params', 'param', 'validate!'
          @descriptor.respond_to?(method)
        else
          super
        end
      end

      def method_missing(method, *args, &block)
        if respond_to?(method)
          @descriptor.send(method, *args, &block)
        else
          super
        end
      end
    end
  end
end
