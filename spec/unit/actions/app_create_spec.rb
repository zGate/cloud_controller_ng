require 'spec_helper'

module VCAP::CloudController
  describe AppCreate do
    let(:user) { double(:user, guid: 'single') }
    subject(:app_create) { AppCreate.new(user, 'quotes') }

    describe '#create' do
      let(:space) { Space.make }
      let(:space_guid) { space.guid }
      let(:environment_variables) { { 'BAKED' => 'POTATO' } }
      let(:buildpack) { Buildpack.make }

      it 'create an app' do
        message = AppCreateMessage.new(
          'name'                  => 'my-app',
          'space_guid'            => space_guid,
          'environment_variables' => environment_variables,
          'buildpack'             => buildpack.name
        )

        app = app_create.create(message)

        expect(app.name).to eq('my-app')
        expect(app.space).to eq(space)
        expect(app.environment_variables).to eq(environment_variables)
        expect(app.buildpack).to eq(buildpack.name)
      end

      it 're-raises validation errors' do
        message = AppCreateMessage.new('name' => '', 'space_guid' => space_guid)
        expect {
          app_create.create(message)
        }.to raise_error(AppCreate::InvalidApp)
      end

      it 'creates an audit event' do
        message = AppCreateMessage.new('name' => 'my-app', 'space_guid' => space_guid, 'environment_variables' => environment_variables)
        app = app_create.create(message)
        event = Event.last
        expect(event.type).to eq('audit.app.create')
        expect(event.actor).to eq('single')
        expect(event.actor_name).to eq('quotes')
        expect(event.actee_type).to eq('v3-app')
        expect(event.actee).to eq(app.guid)
      end

      context 'when a buildpack is requested' do
        context 'but the buildpack does not exist' do
          it 'raises an error' do
            message = AppCreateMessage.new(
              'name'                  => 'my-app',
              'space_guid'            => space_guid,
              'environment_variables' => environment_variables,
              'buildpack'             => 'made-up-buildpack'
            )

            expect { app_create.create(message) }.to raise_error('buildpack not found')
          end
        end


        context 'and the buildpack is an invalid url' do
          it 'raises an error' do
            message = AppCreateMessage.new(
              'name'                  => 'my-app',
              'space_guid'            => space_guid,
              'environment_variables' => environment_variables,
              'buildpack'             => 'http://invalid url with spaces.buildpack.com'
            )

            expect { app_create.create(message) }.to raise_error('buildpack not found')
          end
        end

        context 'and the buildpack is a valid url' do
          it 'saves the url' do
            message = AppCreateMessage.new(
              'name'                  => 'my-app',
              'space_guid'            => space_guid,
              'environment_variables' => environment_variables,
              'buildpack'             => 'http://www.buildpack.com'
            )

            app = app_create.create(message)
            expect(app.buildpack).to eq('http://www.buildpack.com')
          end
        end
      end
    end
  end
end
