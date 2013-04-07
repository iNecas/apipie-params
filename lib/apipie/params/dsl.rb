module Apipie
  module Params
    module DSL
      def _apipie_params_dsl_data
        @_apipie_params_dsl_data ||= _apipie_params_dsl_data_init
      end

      def _apipie_params_dsl_data_init
        @_apipie_params_dsl_data = []
      end

      # Describe method's parameter
      #
      # Example:
      #   param :greeting, String, :desc => "arbitrary text", :required => true
      #
      def param(param_name, descriptor_arg, desc_or_options = nil, options = {}, &block) #:doc:
        if desc_or_options.is_a? String
          options = options.merge(:desc => desc_or_options)
        end
        _apipie_params_dsl_data << [param_name,
                                    descriptor_arg,
                                    options,
                                    block]
      end

      # +descriptor+ might be instance of Descriptor::Base or
      # something that has it in :descriptor method
      def array_of(descriptor)
        descriptor = if descriptor.is_a? Descriptor::Base
                     elsif descriptor.respond_to?(:descriptor)
                       descriptor.descriptor
                     end
        Descriptor::Array.new(descriptor, {})
      end
    end

  end
end
