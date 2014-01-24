module VCAP::CloudController
  class AppSummariesController < ApiController
    def summary
      guid = params[:guid]
      app = App.find(guid: guid) || raise(VCAP::Errors::AppNotFound.new(guid))
      authorization.authorize!(:read, app)
      render json: AppSummaryPresenter.new(app).to_hash
    end
  end
end
