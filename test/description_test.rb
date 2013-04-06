require 'test_helper'

module Apipie
  module Params
    class DescriptionTest < Test::Unit::TestCase

      def test_define
        description = Description.define do
          param :name,    String
          param :age,     Integer, 'in years'
          param :address, Hash do
            param :street, String
            param :zip,    String
          end
        end

        assert_equal [:name, :age, :address], description.params.map(&:name)
        assert_equal [:street, :zip], description.param(:address).params.map(&:name)
      end

      def test_params
        description = Description.new('test', nil, {})
        descriptor_with_params =
          Descriptor::Hash.new(description,
                               Proc.new { param(:test, String) },
                               {})
        descriptor_without_params = Descriptor::Type.new(description, String, {})

        description.descriptor = descriptor_with_params
        assert description.respond_to?(:params)
        assert description.respond_to?(:param)

        description.descriptor = descriptor_without_params
        assert !description.respond_to?(:params)
        assert !description.respond_to?(:param)
      end

      def test_validate
        description = Description.new('test', String, {})
        description.validate!('123')
        assert_raise Errors::Invalid do
          description.validate!(123)
        end
      end

    end
  end
end
