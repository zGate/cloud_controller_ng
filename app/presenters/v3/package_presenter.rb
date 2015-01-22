module VCAP::CloudController
  class PackagePresenter
    def initialize(pagination_presenter=PaginationPresenter.new)
      @pagination_presenter = pagination_presenter
    end

    def present_json_list(paginated_result)
      packages = paginated_result.records
      package_hashes = packages.collect{|p| package_hash(p) }

      paginated_response = {
        pagination: @pagination_presenter.present_pagination_hash(paginated_result, '/v3/packages'),
        resources:  package_hashes
      }

      MultiJson.dump(paginated_response, pretty: true)
    end

    def package_hash(package)
      p package
      p AppModel.count
      {
        guid: package.guid,
        type: package.type,
        hash: package.package_hash,
        url: package.url,
        state: package.state,
        error: package.error,
        created_at: package.created_at,
        _links: {
          self: {
            href: "/v3/packages/#{package.guid}"
          },
          upload: {
            href: "/v3/packages/#{package.guid}/upload",
          },
          space: {
            href: "/v2/spaces/#{package.app.space_guid}",
          },
        },
      }
    end

    def present_json(package)
      package_hash = package_hash(package)

      MultiJson.dump(package_hash, pretty: true)
    end
  end
end
