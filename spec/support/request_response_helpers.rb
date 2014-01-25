module RequestResponseHelpers
  def decoded_response(options={})
    Yajl::Parser.parse(last_response.body, options)
  end
end
