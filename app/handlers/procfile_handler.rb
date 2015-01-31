require 'handlers/processes_handler'

module VCAP::CloudController
  class ProcfileHandler
    class Unauthorized < StandardError; end

    def initialize(apps_handler, processes_handler)
      @apps_handler = apps_handler
      @processes_handler = processes_handler
    end

    def process_procfile(app, procfile, access_context)
      raise Unauthorized if access_context.cannot?(:update, app)

      base_message = { app_guid: app.guid, space_guid: app.space_guid }
      app.db.transaction do
        app.lock!
        types = []
        procfile.each do |(type, command)|
          type = type.to_s
          types << type
          existing_process = App.where(app_guid: app.guid, type: type).first
          if existing_process
            existing_process.update(command: command)
          else
            create_message = ProcessCreateMessage.new(base_message.merge(type: type, command: command))
            process = @processes_handler.create(create_message, access_context)
            @apps_handler.add_process(app, process, access_context)
          end
        end
        App.where(app_guid: app.guid).exclude(type: types).delete
      end
    end
  end
end
