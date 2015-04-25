require 'spec_helper'

module VCAP::CloudController
  describe AppObserver do
    describe 'path' do
      def assert_valid_path(path, expected)
        transformed = VCAP::CloudController::RouteAttributeTransformer.new.transform({
          'host' => 'h', 'path' => path
        })
        expect(transformed['path']).to eq(expected)
      end

      def assert_invalid_path(path)
        expect {
          VCAP::CloudController::RouteAttributeTransformer.new.transform({
            'host' => 'h', 'path' => path
          })
        }.to raise_error Errors::ApiError
      end

      context 'decoded paths' do
        it 'should not allow a path of just slash' do
          assert_invalid_path('/')
        end

        it 'should not allow a blank path' do
          assert_invalid_path('')
        end

        it 'should not allow path that does not start with a slash' do
          assert_invalid_path('bar')
        end

        it 'should allow a path starting with a slash' do
          assert_valid_path('/foo', '/foo')
        end

        it 'should allow a multi-part path' do
          assert_valid_path('/foo/bar', '/foo/bar/')
        end

        it 'should allow a multi-part path ending with a slash' do
          assert_valid_path('/foo/bar/', '/foo/bar')
        end

        it 'should allow equal sign as part of the path' do
          assert_valid_path('/foo=bar', '/foo=bar')
        end

        it 'should not allow question mark' do
          assert_invalid_path('/foo?a=b')
        end

        it 'should not allow trailing question mark' do
          assert_invalid_path('/foo?')
        end

        it 'should not allow non-ASCII characters in the path' do
          assert_invalid_path('/barΩ')
        end
      end

      context 'encoded paths' do
        it 'should not allow a path of just slash' do
          assert_invalid_path('%2F')
        end

        it 'should not allow a path that does not start with slash' do
          assert_invalid_path('%20space')
        end

        it 'should not allow a path that contains ?' do
          assert_invalid_path('/%3F')
        end

        it 'should allow a path that beginst with an escaped slash' do
          assert_valid_path('%2Fpath', '/path')
        end

        it 'should allow  all other escaped chars in a proper url' do
          assert_valid_path('/a%20space', '/a space')
        end
      end
    end
  end
end
