require 'spec_helper'
require 'models/v3/mappers/process_mapper'

module VCAP::CloudController
  describe ProcessMapper do
    describe '.map_model_to_domain' do
      let(:model) { AppFactory.make }

      it 'maps App to AppProcess' do
        process = ProcessMapper.map_model_to_domain(model)

        expect(process.guid).to eq(model.guid)
        expect(process.name).to eq(model.name)
        expect(process.memory).to eq(model.memory)
        expect(process.instances).to eq(model.instances)
        expect(process.disk_quota).to eq(model.disk_quota)
        expect(process.space_guid).to eq(model.space.guid)
        expect(process.stack_guid).to eq(model.stack.guid)
        expect(process.state).to eq(model.state)
        expect(process.command).to eq(model.command)
        expect(process.buildpack).to be_nil
        expect(process.health_check_timeout).to eq(model.health_check_timeout)
        expect(process.docker_image).to eq(model.docker_image)
        expect(process.environment_json).to eq(model.environment_json)
      end
    end

    describe '.map_domain_to_model' do
      context "and the app has been saved" do
        let(:model) { AppFactory.make }

        it 'maps AppProcess to App' do
          model1 = App.find(guid: model.guid)
          process = ProcessMapper.map_model_to_domain(model1)
          model2 = ProcessMapper.map_domain_to_model(process)
          values1 = model1.values
          values2 = model2.values
          # Sequel reads package_pending_since from the database with differing
          # milliseconds
          values1.delete(:package_pending_since) && values2.delete(:package_pending_since)
          expect(values1).to eq(values2)
        end
      end

      context "and the app has not been persisted" do
        let(:model) { App.new }

        it 'maps AppProcess to App' do
          process = ProcessMapper.map_model_to_domain(model)
          model2 = ProcessMapper.map_domain_to_model(process)

          # Sequel reads package_pending_since from the database with differing
          # milliseconds
          expect(model.values.delete(:instances)).to eq(model2.values.delete(:instances))
          expect(model.values.delete(:memory)).to eq(model2.values.delete(:memory))
        end
      end
    end
  end
end
