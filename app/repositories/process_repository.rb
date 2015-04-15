require 'models/v3/mappers/process_mapper'

module VCAP::CloudController
  class ProcessRepository
    class MutationAttemptWithoutALock < StandardError; end
    class InvalidProcess < StandardError; end
    class ProcessNotFound < StandardError; end

    def new_process(opts)
      App.new(opts)
    end

    def update!(desired_process)
      raise MutationAttemptWithoutALock if !@lock_acquired

      desired_process.save
    rescue Sequel::ValidationFailed => e
      raise InvalidProcess.new(e.message)
    end

    def create!(desired_process)
      desired_process.save
    rescue Sequel::ValidationFailed => e
      raise InvalidProcess.new(e.message)
    end

    def find_by_guid(guid)
      App.where(guid: guid).first
    end

    def find_for_show(guid)
      process_model = App.where(apps__guid: guid).eager_graph(:space).all.first
      return nil, nil if process_model.nil?
      [process_model, process_model.space]
    end

    def find_for_update(guid)
      App.db.transaction do
        # We need to lock the row in the apps table. However we cannot eager
        # load associations while using the for_update method. Therefore we
        # need to fetch the App twice. This allows us to only make 2 queries,
        # rather than 3-4.
        App.for_update.where(guid: guid).first
        process_model = App.where(apps__guid: guid).
          eager_graph(:stack, space: :organization).all.first

        return if process_model.nil? && yield(nil, nil, [])

        neighboring_processes = []
        if process_model.app
          process_model.app.processes.each do |p|
            neighboring_processes << ProcessMapper.map_model_to_domain(p) if p.guid != process_model.guid
          end
        end

        @lock_acquired = true
        begin
          yield process_model, process_model.space, neighboring_processes
        ensure
          @lock_acquired = false
        end
      end
    end
  end
end
