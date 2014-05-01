module VCAP::CloudController
  class RestagesController < RestController::ModelController
    path_base "apps"
    model_class_name :App

    post "#{path_guid}/restage", :restage
    def restage(guid)
      app = find_guid_and_validate_access(:read, guid)

      if app.pending?
        raise VCAP::Errors::ApiError.new_from_details("NotStaged")
      end

      restage_job = Jobs::Runtime::Restage.new(guid)
      job = Jobs::Enqueuer.new(restage_job, queue: "cc-generic").enqueue
      [HTTP::CREATED, JobPresenter.new(job).to_json]
    end
  end
end
