require 'test_helper'

module Apipie
  module Params
    class DescriptionTest < Test::Unit::TestCase

      def test_define
        person_description = Params.define do
          param :name,    String
          param :age,     :number, 'in years'
          param :address, Hash do
            param :street, String
            param :zip,    String
          end
        end

        assert_equal [:name, :age, :address], person_description.params.map(&:name)
        assert_equal [:street, :zip], person_description.param(:address).params.map(&:name)

        classroom_description = Params.define do
          param :name, String
          param :teacher, person_description
          param :students, array_of(person_description)
        end

        teacher_description = classroom_description.param(:teacher)
        assert_equal [:name, :age, :address], teacher_description.params.map(&:name)
        students_description = classroom_description.param(:students)
        assert_instance_of Descriptor::Array, students_description.descriptor
        assert_equal [:name, :age, :address], students_description.params.map(&:name)
      end

      def test_params
        description = Description.new('test', nil, {})
        descriptor_with_params =
          Descriptor::Hash.new(Proc.new { param(:test, String) }, {})
        descriptor_without_params = Descriptor::String.new({})

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
