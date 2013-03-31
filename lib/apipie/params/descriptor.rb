module Apipie
  module Params
    module Descriptor

      class Base
        attr_accessor :param_description

        def initialize(param_description, options)
          @param_description = param_description
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
        def self.find(param_description, argument, options, block)
          @descriptor_classes.each do |descriptor_class|
            descriptor = descriptor_class.build(param_description,
                                                argument,
                                                options,
                                                block)
            return descriptor if descriptor
          end
          return nil
        end

        # return true of false if the value is valid or not. Used by
        # default by the +validate!+ method
        def valid?(value)
          raise NotImplementedError, 'abstract method'
        end

        # to be used in the error description and json representation
        def description
          ""
        end

        # this is the method to determine if the value is valid or
        # raise Params::Errors::Invalid or Params::Errors::Missing if
        # it's not. By default, it uses +valid?+ to determine it.
        # you can overwrite the method
        def validate!(value)
          raise invalid_param_error(value) unless valid?(value)
        end

        def invalid_param_error(error_value)
          Params::Errors::Invalid.new(@param_description, error_value, description)
        end

        def to_json
          self.description
        end

        def merge_with(other_descriptor)
          raise NotImplementedError, "Dont know how to merge #{self.inspect} with #{other_descriptor.inspect}"
        end

      end

      # validate arguments type
      class Type < Base

        def self.build(param_description, type, options, block)
          if type.is_a?(Class) && block.nil?
            self.new(param_description, type, options)
          end
        end

        def initialize(param_description, type, options)
          super(param_description, options)
          @type = type
        end

        def valid?(value)
          value.is_a?(@type)
        end

        def description
          "Must be #{@type}"
        end

      end

      # validate arguments value with regular expression
      class Regexp < Base

        def self.build(param_description, regexp, options, block)
          self.new(param_description, regexp, options) if regexp.is_a? ::Regexp
        end

        def initialize(param_description, regexp, options)
          super(param_description, options)
          @regexp = regexp
        end

        def valid?(value)
          value =~ @regexp
        end

        def description
          "Must match regular expression /#{@regexp.source}/."
        end

      end

      # arguments value must be one of given in array
      class Enum < Base

        def self.build(param_description, enum, options, block)
          if enum.is_a?(::Array) && block.nil?
            self.new(param_description, enum, options)
          end
        end

        def initialize(param_description, enum, options)
          super(param_description, options)
          @enum = enum
        end

        def valid?(value)
          @enum.include?(value)
        end

        def description
          "Must be one of: #{@enum.join(', ')}."
        end

      end

      class Proc < Base

        def self.build(param_description, proc, options, block)
          if proc.is_a?(::Proc) && proc.arity == 1
            self.new(param_description, proc, options)
          end
        end

        def initialize(param_description, proc, options)
          super(param_description, options)
          @proc = proc
        end

        def valid?(value)
          (@proc.call(value)) == true
        end

        def invalid_param_error(error_value)
          Params::Errors::Invalid.new(@param_description, error_value, @proc.call(error_value))
        end

      end

      class Hash < Base

        def self.inherited(subclass)
          Base.inherited(subclass)
        end

        class DSL
          include Params::DSL

          def initialize(param_group, &block)
            @param_group = param_group
            instance_eval(&block)
          end

          # where the group definition should be looked up when no scope
          # given. This is expected to return a controller.
          def _apipie_params_default_group_scope
            @param_group && @param_group[:scope]
          end

        end

        def self.build(param_description, argument, options, block)
          if block.is_a?(::Proc) && block.arity <= 0 && argument == ::Hash
            self.new(param_description, block, options)
          end
        end

        def initialize(param_description, block, options)
          super(param_description, options)
          @dsl_data = DSL.new(options[:param_group], &block)._apipie_params_dsl_data
          # specifying action_aware on Hash influences the child params,
          # not the hash param itself: assuming it's required when
          # updating as well
          if param_description.options[:action_aware] && param_description.options[:required]
            param_description.required = true
          end
        end

        def params
          @params ||= @dsl_data.map do |name, arg, options, block|
            options[:parent] = self.param_description
            Description.new(name, arg, options, &block)
          end
          return @params
        end

        def param(param_name)
          params.find { |param| param.name.to_s == param_name.to_s }
        end

        def validate!(value)
          # TODO: validate the type itself first
          params.each do |description|
            # TODO: fix configuration
            #if Apipie.configuration.validate_presence?
            if description.required && !value.has_key?(key)
              raise ParamMissing.new(k)
            end
            #end
            # TODO: fix configuration
            #if Apipie.configuration.validate_value?
            key = description.name
            description.validate!(value[key]) if value.has_key?(key)
            #end
          end
          return true
        end

        def description
          "Must be a Hash"
        end


        def merge_with(other_descriptor)
          if other_descriptor.is_a? self.class
            @params = Description.unify(self.params + other_descriptor.params)
            prepare_hash_params
          else
            super
          end
        end

      end

      class Array < Hash

        def self.build(param_description, argument, options, block)
          if argument == ::Array && block.is_a?(::Proc)
            self.new(param_description, block, options)
          end
        end

        def validate!(array)
          # TODO: validate the type itself
          array.each do |value|
            super(value)
          end
          return true
        end

        def description
          "Must be an Array"
        end

      end

      # special type of descriptor: we say that it's not specified
      class Undef < Base

        def self.build(param_description, argument, options, block)
          if argument == :undef
            self.new(param_description, options)
          end
        end

        def valid?(value)
          true
        end

      end

      class Number < Base

        def self.build(param_description, argument, options, block)
          if argument == :number
            self.new(param_description, options)
          end
        end

        def valid?(value)
          self.class.valid?(value)
        end

        def description
          "Must be a number."
        end

        def self.valid?(value)
          value.to_s =~ /\A(0|[1-9]\d*)\Z$/
        end

      end

      class Boolean < Base

        def self.build(param_description, argument, options, block)
          if argument == :bool
            self.new(param_description, options)
          end
        end

        def valid?(value)
          %w[true false].include?(value.to_s)
        end

        def description
          "Must be 'true' or 'false'"
        end

      end

    end
  end
end
