require 'test_helper'

module Apipie
  module Params
    describe Descriptor do

      class CustomDescriptor < Descriptor::Base

        def self.build(param_description, argument, options, block)
          if argument == :custom
            self.new(param_description, options)
          end
        end

        def valid?(value)
          value == 'valid'
        end

        def description
          'value has to be "value"'
        end

      end

      def self.describe_validator(valid_value, invalid_value, exception_matcher)
        describe 'valid value' do
          let(:value) { valid_value }

          it 'succeeds' do
            subject.validate!(value)
          end
        end

        describe 'invalid value' do
          let(:value) { invalid_value }

          it 'fails' do
            exception = lambda do
              subject.validate!(value)
            end.must_raise Params::Errors::Invalid
            exception.message.must_match(exception_matcher)
          end
        end
      end

      describe 'custom descriptor' do
        subject { Description.new('test', :custom, {}) }
        describe_validator('valid', 'invalid', /value has to be "value"/)
      end

      describe 'type descriptor' do
        subject { Description.new('test', String, {}) }
        describe_validator('valid', :invalid, /Must be String/)
      end

      describe 'regexp descriptor' do
        subject { Description.new('test', /\Avalid/, {}) }
        describe_validator('valid', 'invalid', /Must match/)
      end

      describe 'enum descriptor' do
        subject { Description.new('test', ['valid', 'valider'], {}) }
        describe_validator('valid', 'invalid', /Must be one of/)
      end

      describe 'proc descriptor' do
        subject { Description.new('test', lambda { |x| x == 'valid' ? true : 'Has to be valid' }, {}) }
        describe_validator('valid', 'invalid', /Has to be valid/)
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
        describe_validator({:name => "valid"}, {:name => :invalid}, /Must be String/)

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
            street_description.descriptor.must_be_kind_of Descriptor::Type
          end
        end
      end

      describe 'array descriptor' do
        subject do
          Description.new('test', ::Array, {}) do
            param :name, String
          end
        end

        describe_validator([{:name => "valid"}], [{:name => :invalid}], /Must be String/)
      end

      describe 'undef descriptor' do
        subject { Description.new('test', :undef, {}) }

        describe 'valid value' do
          let(:value) { 'whatever' }

          it 'succeeds' do
            subject.validate!(value)
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

      # TODO: define
      describe 'merge_with' do
        it 'is defined' do
          skip
        end
      end

    end
  end
end
