module VCAP::CloudController
  class BuildpackNameValidator
    def valid?(buildpack_name)
      if !valid_url?(buildpack_name)
        buildpack = Buildpack.find(name: buildpack_name)
        return false if buildpack.nil?
      end

      true
    end

    def valid_url?(url)
      begin
        uri = URI.parse(url)
        return false if !(uri.kind_of?(URI::HTTP) || uri.kind_of?(URI::HTTPS))
      rescue URI::InvalidURIError
        return false
      end

      true
    end
  end
end
