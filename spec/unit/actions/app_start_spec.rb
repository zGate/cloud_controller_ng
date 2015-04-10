require 'spec_helper'
require 'actions/app_start'

module VCAP::CloudController
  describe AppStart do
    let(:user) { double(:user, guid: '7') }
    let(:user_email) { '1@2.3' }
    let(:app_start) { AppStart.new(user, user_email) }

    describe '#start' do
      let(:environment_variables) { { 'FOO' => 'bar' } }
      let(:process1) { AppFactory.make(state: 'STOPPED') }
      let(:process2) { AppFactory.make(state: 'STOPPED') }

      let(:app_model) do
        AppModel.make({
          desired_state: 'STOPPED',
          desired_droplet_guid: droplet_guid,
          environment_variables: environment_variables
        })
      end

      context 'when the desired_droplet does not exist' do
        let(:droplet_guid) { nil }

        it 'raises a DropletNotFound exception' do
          expect {
            app_start.start(app_model)
          }.to raise_error(AppStart::DropletNotFound)
        end

        context 'and the app has a procfile' do
          it 'raises a DropletNotFound exception' do
            app_model.update(procfile: 'web: app_model')

            expect {
              app_start.start(app_model)
            }.to raise_error(AppStart::DropletNotFound)
          end
        end
      end

      context 'when the desired_droplet exists' do
        let(:droplet) do
          DropletModel.make(procfile: "web: a\nworker: b")
        end
        let(:droplet_guid) { droplet.guid }

        it 'sets the desired state on the app' do
          app_start.start(app_model)
          expect(app_model.desired_state).to eq('STARTED')
        end

        it 'expands procfile to processes' do
          app_start.start(app_model)

          processes = app_model.processes.sort_by(&:type)
          expect(processes[0].type).to eq('web')
          expect(processes[0].command).to eq('a')
          expect(processes[1].type).to eq('worker')
          expect(processes[1].command).to eq('b')
        end

        it 'creates an audit event' do
          app_start.start(app_model)

          event = Event.last
          expect(event.type).to eq('audit.app.start')
          expect(event.actor).to eq('7')
          expect(event.actor_name).to eq(user_email)
          expect(event.actee_type).to eq('v3-app')
          expect(event.actee).to eq(app_model.guid)
        end

        context 'and the droplet has a package' do
          let(:droplet) { DropletModel.make(package_guid: package.guid, procfile: 'web: x') }
          let(:package) { PackageModel.make(package_hash: 'some-awesome-thing', state: PackageModel::READY_STATE) }

          it 'sets the package hash correctly on the process' do
            app_start.start(app_model)
            app_model.processes.each do |process|
              expect(process.package_hash).to eq(package.package_hash)
              expect(process.package_state).to eq('STAGED')
            end
          end
        end

        context 'and the droplet does not have a package' do
          it 'sets the package hash to unknown' do
            app_start.start(app_model)
            app_model.processes.each do |process|
              expect(process.package_hash).to eq('unknown')
              expect(process.package_state).to eq('STAGED')
            end
          end
        end

        it 'prepares the sub-processes of the app' do
          app_start.start(app_model)
          app_model.processes.each do |process|
            expect(process.needs_staging?).to eq(false)
            expect(process.started?).to eq(true)
            expect(process.state).to eq('STARTED')
            expect(process.environment_json).to eq(app_model.environment_variables)
          end
        end

        it 'favors app procfile over droplets' do
          app_model.update(procfile: 'web: y')
          app_start.start(app_model)

          expect(app_model.processes[0].command).to eq('y')
          expect(app_model.processes.size).to eq(1)
        end

        context 'and the app and droplet have no procfile' do
          it 'raises a ProcfileNotFound error' do
            app_model.update(procfile: nil)
            droplet.update(procfile: nil)
            expect {
              app_start.start(app_model)
            }.to raise_error(ProcfileParse::ProcfileNotFound)
          end
        end
      end
    end
  end
end
