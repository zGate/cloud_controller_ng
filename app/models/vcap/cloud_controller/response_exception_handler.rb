module VCAP::CloudController
  class ResponseExceptionHandler
    include Sinatra::VCAP::Helpers

    def initialize(logger)
      @logger = logger
    end

    def handle(response, exception)
      raise exception if !exception.respond_to?(:error_code)

      response_code = exception.respond_to?(:response_code) ? exception.response_code : 500
      payload_hash = error_payload(exception)

      log_level = (400..499).cover?(response_code) ? :info : :error
      @logger.public_send(log_level, "Request failed: #{response_code}: #{payload_hash}")

      response.status = response_code
      response.body = Yajl::Encoder.encode(payload_hash).concat("\n")
    end
  end
end
