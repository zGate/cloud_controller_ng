module VCAP::CloudController
  class ResourceMatchesController < RestController::BaseController
    put "/v2/resource_match", :match
    def match
      raise ApiError.new_from_details("NotAuthorized") unless allowed?
      fingerprints_all_clientside_bits = MultiJson.load(body)
      fingerprints_existing_in_blobstore = ResourcePool.instance.match_resources(fingerprints_all_clientside_bits)
      MultiJson.dump(fingerprints_existing_in_blobstore)
    end

    private
    def allowed?
      enabled? && user
    end

    def enabled?
      SecurityContext.admin? || FeatureFlag.enabled?("app_bits_upload")
    end
  end
end
