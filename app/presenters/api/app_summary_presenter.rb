class AppSummaryPresenter
  def initialize(app)
    @app = app
  end

  def to_hash
    # Do all the eager loading
    {
      guid: @app.guid,
      name: @app.name,
      memory: @app.memory,
      instances: @app.instances,
      disk_quota: @app.disk_quota,
      command: @app.command,
      console: @app.console,
      buildpack: @app.buildpack,
      detected_buildpack: @app.detected_buildpack,
      debug: @app.debug,
      environment_json: @app.environment_json,
      health_check_timeout: @app.health_check_timeout,
      package_state: @app.package_state,
      production: @app.production,
      version: @app.version,
      system_env_json: @app.system_env_json,
      state: @app.state,
      staging_task_id: @app.staging_task_id,
      running_instances: @app.running_instances,

      space_guid: @app.space.guid,
      stack_guid: @app.stack.guid,

      routes: routes,
      services: services,
      available_domains: private_domains + shared_domains,
    }
  end

  private

  def routes
    @app.routes.map do |route|
      {
        guid: route.guid,
        host: route.host,
        domain: {
          guid: route.domain.guid,
          name: route.domain.name,
        },
      }
    end
  end

  def services
    @app.service_bindings.map do |service_binding|
      service_instance = service_binding.service_instance
      send(service_instance.class.name.demodulize.underscore, service_instance)
    end
  end

  def user_provided_service_instance(service_instance)
    {
      guid: service_instance.guid,
      name: service_instance.name,
      bound_app_count: service_instance.service_bindings_dataset.count,
    }
  end

  def managed_service_instance(service_instance)
    service_plan = service_instance.service_plan
    service = service_plan.service
    {
      guid: service_instance.guid,
      name: service_instance.name,
      bound_app_count: service_instance.service_bindings_dataset.count,
      dashboard_url: service_instance.dashboard_url,
      service_plan: {
        guid: service_plan.guid,
        name: service_plan.name,
        service: {
          guid: service.guid,
          label: service.label,
          provider: service.provider,
          version: service.version,
        },
      },
    }
  end

  def private_domains
    @app.space.organization.private_domains.map do |private_domain|
      {
        guid: private_domain.guid,
        name: private_domain.name,
        owning_organization_guid: private_domain.owning_organization.guid,
      }
    end
  end

  def shared_domains
    VCAP::CloudController::SharedDomain.all.map do |shared_domain|
      {
        guid: shared_domain.guid,
        name: shared_domain.name,
      }
    end
  end
end
