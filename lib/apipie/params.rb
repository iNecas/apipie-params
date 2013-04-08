module Apipie
  module Params
    def self.define(&block)
      Params::Description.define(&block)
    end
  end
end
