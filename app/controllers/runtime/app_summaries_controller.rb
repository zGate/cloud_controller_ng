module VCAP::CloudController
  class AppSummariesController < ApiController
    def summary
      guid = params[:guid]
      app = App.find(guid: guid) || raise(VCAP::Errors::AppNotFound.new(guid))
      authorization.authorize!(:read, app)

      app_info = {
        guid: app.guid,
        name: app.name,
        routes: app.routes.map(&:as_summary_json),
        running_instances: app.running_instances,
        services: app.service_bindings.map { |service_binding| service_binding.service_instance.as_summary_json },
        available_domains: (app.space.organization.private_domains + SharedDomain.all).map(&:as_summary_json)
      }.merge(app.to_hash)

      render json: app_info
    end

    private

    def inject_dependencies(dependency_locator)
      super
      @logger = Steno.logger("cc.app-summaries-controller")
    end
  end
end
