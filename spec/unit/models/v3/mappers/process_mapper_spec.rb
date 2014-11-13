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
      let(:space) { Space.make }
      let(:stack) { Stack.make }

      let(:standard_opts){stuff}
      let(:custom_opts){ {} }
      let(:all_opts) {standard_opts.merge(custom_opts)}
      let(:process){AppProcess.new(all_opts)}

      context 'and the app has been saved' do
        let(:app) { AppFactory.make }
        let(:process) do
          AppProcess.new({
            guid:                 app.guid,
            name:                 'some-name',
            space_guid:           space.guid,
            stack_guid:           stack.guid,
            disk_quota:           32,
            memory:               456,
            instances:            51,
            state:                'STARTED',
            command:              'start-command',
            buildpack:            'buildpack',
            health_check_timeout: 3,
            docker_image:         'docker_image',
            environment_json:     'env_json'
          })
        end

        it 'maps AppProcess to App' do
          model = ProcessMapper.map_domain_to_model(process)

          expect(model.guid).to eq(app.guid)
          expect(model.name).to eq('some-name')
          expect(model.memory).to eq(456)
          expect(model.instances).to eq(51)
          expect(model.disk_quota).to eq(32)
          expect(model.space_guid).to eq(space.guid)
          expect(model.stack_guid).to eq(stack.guid)
          expect(model.state).to eq('STARTED')
          expect(model.command).to eq('start-command')
          expect(model.buildpack.url).to eq('buildpack')
          expect(model.health_check_timeout).to eq(3)
          expect(model.docker_image).to eq('docker_image:latest')
          expect(model.environment_json).to eq('env_json')
        end
      end

      context 'and the app has not been persisted' do
        let(:process) do
          AppProcess.new({
            name:                 'some-name',
            space_guid:           space.guid,
            stack_guid:           stack.guid,
            disk_quota:           32,
            memory:               456,
            instances:            51,
            state:                'STARTED',
            command:              'start-command',
            buildpack:            'buildpack',
            health_check_timeout: 3,
            docker_image:         'docker_image',
            environment_json:     'env_json'
          })
        end

        it 'maps AppProcess to App' do
          model = ProcessMapper.map_domain_to_model(process)

          expect(model.guid).to be_nil
          expect(model.name).to eq('some-name')
          expect(model.memory).to eq(456)
          expect(model.instances).to eq(51)
          expect(model.disk_quota).to eq(32)
          expect(model.space_guid).to eq(space.guid)
          expect(model.stack_guid).to eq(stack.guid)
          expect(model.state).to eq('STARTED')
          expect(model.command).to eq('start-command')
          expect(model.buildpack.url).to eq('buildpack')
          expect(model.health_check_timeout).to eq(3)
          expect(model.docker_image).to eq('docker_image:latest')
          expect(model.environment_json).to eq('env_json')
        end

        context 'and some values are nil' do
          let(:process) do
            AppProcess.new({
              name:                 'some-name',
              space_guid:           space.guid,
              stack_guid:           stack.guid,
              disk_quota:           32,
              memory:               456,
              instances:            nil,
              state:                'STARTED',
              command:              'start-command',
              buildpack:            'buildpack',
              health_check_timeout: 3,
              docker_image:         'docker_image',
              environment_json:     'env_json'
            })
          end

          it 'does not map map them' do
            model = ProcessMapper.map_domain_to_model(process)

            expect(model.guid).to be_nil
            expect(model.name).to eq('some-name')
            expect(model.memory).to eq(456)
            expect(model.instances).to_not be_nil
            expect(model.disk_quota).to eq(32)
            expect(model.space_guid).to eq(space.guid)
            expect(model.stack_guid).to eq(stack.guid)
            expect(model.state).to eq('STARTED')
            expect(model.command).to eq('start-command')
            expect(model.buildpack.url).to eq('buildpack')
            expect(model.health_check_timeout).to eq(3)
            expect(model.docker_image).to eq('docker_image:latest')
            expect(model.environment_json).to eq('env_json')
          end
        end

        context 'but we search for a persisted app' do
          let(:process) do
            AppProcess.new({
              guid:                 'bogus',
              name:                 'some-name',
              space_guid:           space.guid,
              stack_guid:           stack.guid,
              disk_quota:           32,
              memory:               456,
              instances:            51,
              state:                'STARTED',
              command:              'start-command',
              buildpack:            'buildpack',
              health_check_timeout: 3,
              docker_image:         'docker_image',
              environment_json:     'env_json'
            })
          end

          it 'returns nil' do
            expect(ProcessMapper.map_domain_to_model(process)).to be_nil
          end
        end
      end
    end
  end
end
