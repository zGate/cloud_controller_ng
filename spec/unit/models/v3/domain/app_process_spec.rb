require 'spec_helper'
require 'models/v3/domain/app_process'

module VCAP::CloudController
  describe AppProcess do
    let(:opts) { { 'guid' => 'my_guid' } }

    it 'defaults the name of a process when it has not been provided' do
      expect(AppProcess.new(opts).name).to eq('v3-proc-web-my_guid')
    end

    it 'defaults the type of a process to web when it has not been provided' do
      expect(AppProcess.new(opts).type).to eq('web')
    end

    describe 'equality' do
      let(:process) { AppProcess.new(opts) }

      context 'when comparing a process with itself' do
        it 'returns true' do
          other = process
          expect(process == other).to be_truthy
          expect(process.eql? other).to be_truthy
          expect(process).to eq(other)
        end
      end

      context 'when comparing two processes with the same attributes' do
        it 'returns true' do
          other = AppProcess.new(opts)

          expect(process == other).to be_truthy
          expect(process.eql? other).to be_truthy
          expect(process).to eq(other)
        end
      end

      context 'when comparing two processes with different attributes' do
        it 'returns false' do
          other = AppProcess.new({ 'guid' => 'another_guid' })

          expect(process == other).to be_falsey
          expect(process.eql? other).to be_falsey
          expect(process).to_not eq(other)
        end
      end

      context 'when comparing with a different class' do
        it 'return false' do
          expect(process == 'string').to be_falsey
          expect(process.eql? 'string').to be_falsey
          expect(process).to_not eq('string')
        end
      end
    end
  end
end
