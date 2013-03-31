module Apipie
  module Params
    module DSL
      def _apipie_params_dsl_data
        @_apipie_params_dsl_data ||= _apipie_params_dsl_data_init
      end

      def _apipie_params_dsl_data_clear
        @_apipie_params_dsl_data = nil
      end

      def _apipie_params_dsl_data_init
        @_apipie_params_group = nil
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
                                    options.merge(:param_group => @_apipie_params_group),
                                    block]
      end

      # Reuses param group for this method. The definition is looked up
      # in scope of this controller. If the group was defined in
      # different controller, the second param can be used to specify it.
      # when using action_aware parmas, you can specify :as =>
      # :create or :update to explicitly say how it should behave
      # TODO: make sure this works
      def param_group(name, scope_or_options = nil, options = {})
        if scope_or_options.is_a? Hash
          options.merge!(scope_or_options)
          scope = options[:scope]
        else
          scope = scope_or_options
        end
        scope ||= _apipie_params_default_group_scope
        @_apipie_params_group = {:scope => scope, :name => name, :options => options}
        # TODO: this doesn't work without apipie-rails
        self.instance_exec(&Apipie.get_param_group(scope, name))
      ensure
        @_apipie_params_group = nil
      end

      # where the group definition should be looked up when no scope
      # given. This is expected to return a controller.
      def _apipie_params_default_group_scope
        self
      end
    end

  end
end
