require 'active_support/core_ext/hash/indifferent_access'

module Apipie
  module Params
    module Descriptor

      class Base
        def initialize(options)
          if options.is_a? ::Hash
            @options = options
          else
            @options = {}
          end
        end

        def self.inherited(subclass)
          @descriptor_classes ||= []
          @descriptor_classes.insert 0, subclass
        end

        # find the right descriptor for given options
        def self.find(argument, options, block)
          @descriptor_classes.each do |descriptor_class|
            descriptor = descriptor_class.build(argument, options, block)
            return descriptor if descriptor
          end
          return nil
        end

        # to be used in the error description and json representation
        def description
          ""
        end

        def invalid_param_error(param_description, error_value, errors = [])
          Params::Errors::Invalid.new(param_description, error_value, description)
        end

        def to_json
          self.json_schema
        end

      end

      class JsonSchema < Base
        def self.inherited(subclass)
          Base.inherited(subclass)
        end

        def self.build(*args)
          # this is an abstract class
          nil
        end

        def json_schema
          {'description' => description}
        end


        def validate!(param_description, value)
          encapsulated_value = {'root' => value}
          encapsulated_schema = {
            'type' => 'object',
            'properties' => {'root' => json_schema}
          }
          errors = JSON::Validator.fully_validate(encapsulated_schema,
                                                  encapsulated_value.with_indifferent_access,
                                                  :errors_as_objects => true)

          if errors.any?
            raise invalid_param_error(param_description, value, errors)
          else
            return true
          end
        end

      end

      # validate arguments type
      class String < JsonSchema

        def self.build(type, options, block)
          if type == ::String
            self.new(options)
          end
        end

        def description
          "Must be a string"
        end

        def json_schema
          super.merge('type' => 'string')
        end

      end

      # validate arguments value with regular expression
      class Regexp < JsonSchema

        def self.build(regexp, options, block)
          self.new(regexp, options) if regexp.is_a? ::Regexp
        end

        def initialize(regexp, options)
          super(options)
          @regexp = regexp
        end

        def description
          "Must match regular expression /#{@regexp.source}/."
        end

        def json_schema
          super.merge('type' => 'string', 'pattern' => @regexp.source)
        end

      end

      # arguments value must be one of given in array
      class Enum < JsonSchema

        def self.build(enum, options, block)
          if enum.is_a?(::Array) && block.nil?
            self.new(enum, options)
          end
        end

        def initialize(enum, options)
          super(options)
          @enum = enum
        end

        def description
          "Must be one of: #{@enum.join(', ')}."
        end

        def json_schema
          super.merge('type' => 'any', 'enum' => @enum)
        end

      end

      class Hash < JsonSchema

        class DSL
          include Params::DSL

          def initialize(&block)
            instance_eval(&block)
          end
        end

        def self.build(argument, options, block)
          if block.is_a?(::Proc) && block.arity <= 0 && argument == ::Hash
            self.new(block, options)
          end
        end

        def initialize(block, options)
          super(options)
          @dsl_data = DSL.new(&block)._apipie_params_dsl_data
        end

        def params
          @params ||= @dsl_data.map do |name, arg, options, block|
            Description.new(name, arg, options, &block)
          end
          return @params
        end

        def param(param_name)
          params.find { |param| param.name.to_s == param_name.to_s }
        end

        def description
          "Must be a Hash"
        end

        def json_schema
          properties = params.reduce({}) do |hash, description|
            hash.update(description.name.to_s => description.descriptor.json_schema)
          end
          super.merge('type' => 'object',
                      'properties' => properties)
        end

        def invalid_param_error(param_description, error_value, errors)
          descriptions = errors.map do |error|
            fragment_descriptor(param_description, error[:fragment])
          end
          # TODO: handle multiple errors at the same time
          invalid_param = descriptions.first
          description = invalid_param.descriptor.description
          Params::Errors::Invalid.new(invalid_param, error_value, description)
        end

        def fragment_descriptor(param_description, fragment)
          keys_path = fragment.sub(/\A#\/root\//,'').split('/')
          keys_path.delete_if { |a| a =~ /\A\d+\Z/ }
          keys_path.reduce(param_description) do |description, key|
            description.param(key)
          end
        end

      end

      class Array < Hash

        def self.build(argument, options, block)
          if argument == ::Array && block.is_a?(::Proc)
            self.new(block, options)
          end
        end

        def description
          "Must be an Array"
        end

        def json_schema
          {
            'type' => 'array',
            'items' => super
          }
        end

      end

      # special type of descriptor: we say that it's not specified
      class Undef < JsonSchema

        def self.build(argument, options, block)
          if argument == :undef
            self.new(options)
          end
        end

        def json_schema
          super.merge('type' => 'any')
        end
      end

      class Number < Regexp

        def self.build(argument, options, block)
          if argument == :number
            self.new(self.pattern, options)
          end
        end

        def description
          "Must be a number."
        end

        def self.pattern
          /\A(0|[1-9]\d*)\Z$/
        end

      end

      class Boolean < Enum

        def self.build(argument, options, block)
          if argument == :bool
            self.new(valid_values, options)
          end
        end

        def self.valid_values
          %w[true false]
        end

        def description
          "Must be 'true' or 'false'"
        end

      end

    end
  end
end
