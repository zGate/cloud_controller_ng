module VCAP::CloudController
  class RouteAttributeTransformer
    ROUTE_REGEX = /\A#{URI.regexp}\Z/.freeze
    def transform(attrs)
      if attrs['path']
        path = attrs['path']
        decoded_path = URI.unescape(path)

        if path =~ /%3F/ || path =~ /\?/ || !ROUTE_REGEX.match("pathcheck://#{attrs['host']}#{path}") || decoded_path == '/' || decoded_path[0] != '/'
          raise Errors::ApiError.new_from_details('PathInvalid', attrs['path'])
        end

        attrs.merge('path' => URI.unescape(attrs['path'])) if attrs['path']
      else
        attrs
      end
    end
  end
end
