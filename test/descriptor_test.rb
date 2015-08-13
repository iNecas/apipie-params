require 'test_helper'

module Apipie
  module Params
    describe Descriptor do

      def self.describe_validator(valid_value, invalid_value, exception_matcher)
        describe 'valid value' do
          it 'succeeds' do
            subject.validate!(valid_value)
          end
        end

        describe 'invalid value' do
          it 'fails' do
            exception = lambda do
              subject.validate!(invalid_value)
            end.must_raise Params::Errors::Invalid
            exception.message.must_match(exception_matcher)
          end
        end
      end

      describe 'custom descriptor' do
        subject { Description.new('test', :custom, {}) }
        #describe_validator('valid', 'invalid', /value has to be "value"/)
        it 'allows to extend the default json schema'
      end

      describe 'string descriptor' do
        subject { Description.new('test', String, {}) }
        #describe_validator('valid', :invalid, /Must be a string/)
      end

      describe 'integer descriptor' do
        subject { Description.new('test', Integer, {}) }
        describe_validator(123, '123', /Must be an integer/)
      end

      describe 'regexp descriptor' do
        subject { Description.new('test', /\Avalid/, {}) }
        describe_validator('valid', 'invalid', /Must match/)
      end

      describe 'enum descriptor' do
        subject { Description.new('test', ['valid', 'valider'], {}) }
        describe_validator('valid', 'invalid', /Must be one of/)
      end

      describe 'hash descriptor' do
        subject do
          Description.new('test', Hash, {}) do
            param :name, String
            param :address, Hash do
              param :street, String
              param :zip, String
            end
          end
        end
        # TODO: test require and allow_nil
        describe_validator({:name => "valid"}, {:name => 123}, /Must be a string/)

        describe '#params' do
          it 'returns param descriptions of all keys' do
            name_description, address_description = subject.params
            name_description.name.must_equal :name
            address_description.name.must_equal :address
            address_description.params.map(&:name).must_equal([:street, :zip])
          end
        end

        describe '#param' do
          it 'returns param description for a key' do
            street_description = subject.param(:address).param(:street)
            street_description.name.must_equal :street
            street_description.descriptor.must_be_kind_of Descriptor::String
          end
        end
      end

      describe 'array descriptor' do
        subject do
          Description.new('test', ::Array, {}) do
            param :name, String
          end
        end

        #describe_validator([{:name => "valid"}], [{:name => :invalid}], /Must be a string/)
      end

      describe 'undef descriptor' do
        subject { Description.new('test', :undef, {}) }

        describe 'valid value' do
          it 'succeeds' do
            subject.validate!('whatever')
          end
        end

      end

      describe 'number descriptor' do
        subject { Description.new('test', :number, {}) }
        describe_validator('123', 'a23', /Must be a number/)
      end

      describe 'boolean descriptor' do
        subject { Description.new('test', :bool, {}) }
        describe_validator('true', 'no', /Must be 'true' or 'false'/)
      end

    end
  end
end
