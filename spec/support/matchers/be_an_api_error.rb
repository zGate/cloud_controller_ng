RSpec::Matchers.define :be_an_api_error do |expected|
  match do |actual_response|
    @failure_msgs = []

    actual_http_status = actual_response.status
    expected_http_status = expected.fetch(:response_code)
    if actual_http_status != expected_http_status
      @failure_msgs << "Error HTTP response status was #{actual_http_status.inspect}; " +
                       "expected #{expected_http_status.inspect}"
    end

    decoded_response = Yajl::Parser.parse(actual_response.body)

    actual_keys = decoded_response.keys.sort
    expected_keys = %w(code description error_code types backtrace).sort
    if actual_keys != expected_keys
      @failure_msgs << "Error HTTP response body contained #{actual_keys.inspect}; " +
                       "expected #{expected_keys.inspect}"
    end

    %w(code description error_code types).each do |key|
      actual_value = decoded_response[key]
      expected_value = expected[key.to_sym]
      if actual_value != expected_value
        @failure_msgs << "Error HTTP response body contained value #{actual_value.inspect} for key #{key.inspect}; " +
                         "expected value #{expected_value}"
      end
    end

    @failure_msgs.empty?
  end

  failure_message_for_should { |actual_response| @failure_msgs.join("\n") }
end
