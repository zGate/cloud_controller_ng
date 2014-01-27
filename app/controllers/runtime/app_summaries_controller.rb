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

__END__

module VCAP::CloudController
  class InfoController < ApiController
    skip_before_filter :require_identity!, only: :show

    def show
      info = Info.new(@config)
      authorization.authorize!(:info, info)
      render json: InfoPresenter.new(info).to_hash
    end
  end
end

module VCAP::CloudController
  class BuildpackController < ApiController
    def index
      authorization.authorize!(:index, Buildpack)
      buildpacks = Buildpack.all # do authed query
      render json: CollectionPresenter.new(buildpacks).to_hash

      # BuildpackPresent would actually make a DB query
      # @renderer.render_collection(buildpacks)
    end

    def create
      buildpack = Buildpack.new(BuildpackParams.new(params).to_hash)
      authorization.authorize!(:create, buildpack)
      buildpack.create!
      render json: BuildpackPresenter.new(buildpack).to_hash
    end
  end
end
