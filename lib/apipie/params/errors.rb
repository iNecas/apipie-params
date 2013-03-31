module Apipie
  module Params
    module Errors

      class ParamError < StandardError
        attr_accessor :description

        def initialize(description)
          @description = description
        end
      end

      class Missing < ParamError
        def to_s
          "Missing parameter #{@description.name}"
        end
      end

      class Invalid < ParamError
        attr_accessor :value, :error

        def initialize(description, value, error)
          super(description)
          @value = value
          @error = error
        end

        def to_s
          "Invalid parameter '#{description.name}' value #{@value.inspect}: #{@error}"
        end
      end

    end
  end
end
