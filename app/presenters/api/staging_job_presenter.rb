require_relative "job_presenter"

class StagingJobPresenter < JobPresenter
  def status_url
    "/staging/jobs/#{@object.guid}"
  end
end
