require "spec_helper"

module VCAP::CloudController
  describe AppSummaryPresenter do
    describe "#to_hash" do
      before { SharedDomain.dataset.delete }

      describe "root fields" do
        before do
          @app = AppFactory.make
          @app_double = instance_double("VCAP::CloudController::App", {
            guid: "app-guid",
            name: "app-name",
            memory: 101,
            instances: 102,
            disk_quota: 103,
            command: "app-command",
            console: "app-console",
            debug: "app-debug",
            health_check_timeout: 104,
            production: "app-production",
            version: "app-version",
            state: "app-state",
            staging_task_id: "app-staging-task",
            package_state: "app-package-state",
            buildpack: "app-buildpack",
            detected_buildpack: "app-detected-buildpack",
            environment_json: {"environment" => "json"},
            system_env_json: {"system_env" => "json"},
            running_instances: 105,
            staging_task_id: 106,
            running_instances: 107,

            # associations
            space: @app.space,
            stack: @app.stack,

            routes: [],
            service_bindings: [],
          })
        end

        it "includes all fields" do
          hash = described_class.new(@app_double).to_hash
          expect(hash).to have_no_nils
          expect(hash).to eql(
            guid: "app-guid",
            name: "app-name",
            memory: 101,
            instances: 102,
            disk_quota: 103,
            command: "app-command",
            console: "app-console",
            buildpack: "app-buildpack",
            detected_buildpack: "app-detected-buildpack",
            debug: "app-debug",
            environment_json: {"environment" => "json"},
            health_check_timeout: 104,
            package_state: "app-package-state",
            production: "app-production",
            version: "app-version",
            system_env_json: {"system_env" => "json"},
            state: "app-state",
            staging_task_id: 106,
            running_instances: 107,

            space_guid: @app.space.guid,
            stack_guid: @app.stack.guid,

            # associations
            routes: [],
            services: [],
            available_domains: [],
          )
        end
      end

      describe "routes field" do
        before do
          @app = AppFactory.make
          @route = Route.make(space: @app.space)
          @route.add_app(@app)
        end

        it "includes detailed information about routes" do
          hash = described_class.new(@app).to_hash
          routes_hash = hash.fetch(:routes)
          expect(routes_hash).to have_no_nils
          expect(routes_hash).to match_array([{
            guid: @route.guid,
            host: @route.host,
            domain: {
              guid: @route.domain.guid,
              name: @route.domain.name,
            },
          }])
        end
      end

      describe "services field" do
        before do
          @app = AppFactory.make

          @managed_service_instance = ManagedServiceInstance.make(
            space: @app.space,
            dashboard_url: "service-instance-dashboard-url",
          )
          ServiceBinding.make(app: @app, service_instance: @managed_service_instance)

          @user_provided_service_instance = UserProvidedServiceInstance.make(space: @app.space)
          ServiceBinding.make(app: @app, service_instance: @user_provided_service_instance)
        end

        it "includes detailed information about services" do
          hash = described_class.new(@app).to_hash
          services_hash = hash.fetch(:services)
          expect(services_hash).to have_no_nils
          expect(services_hash).to match_array([{
            guid: @managed_service_instance.guid,
            name: @managed_service_instance.name,
            bound_app_count: 1, # ??
            dashboard_url: "service-instance-dashboard-url",
            service_plan: {
              guid: @managed_service_instance.service_plan.guid,
              name: @managed_service_instance.service_plan.name,
              service: {
                guid: @managed_service_instance.service_plan.service.guid,
                label: @managed_service_instance.service_plan.service.label,
                provider: @managed_service_instance.service_plan.service.provider,
                version: @managed_service_instance.service_plan.service.version,
              },
            },
          },{
            guid: @user_provided_service_instance.guid,
            name: @user_provided_service_instance.name,
            bound_app_count: 1,
          }])
        end
      end

      describe "domains field" do
        before do
          @app = AppFactory.make
          @route = Route.make(space: @app.space)
          @route.add_app(@app)
          @shared_domain = SharedDomain.make
          @private_domain = @route.domain
        end

        it "includes detailed information about domains" do
          hash = described_class.new(@app).to_hash
          domains_hash = hash.fetch(:available_domains)
          expect(domains_hash).to have_no_nils
          expect(domains_hash).to match_array([{
            guid: @private_domain.guid,
            name: @private_domain.name,
            owning_organization_guid: @private_domain.owning_organization.guid,
          },{
            guid: @shared_domain.guid,
            name: @shared_domain.name,
          }])
        end
      end
    end
  end
end
