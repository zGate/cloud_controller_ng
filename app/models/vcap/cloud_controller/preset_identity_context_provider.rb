module VCAP::CloudController
  class PresetIdentityContextProvider
    def initialize(headers, identity_context)
      @headers = headers
      @identity_context = identity_context
    end

    def for_auth_header(auth_token)
      if @headers["HTTP_AUTHORIZATION"] == auth_token
        @identity_context
      else
        raise ArgumentError, "No preset identity_context for provided auth_token"
      end
    end
  end
end
