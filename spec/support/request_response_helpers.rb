module RequestResponseHelpers
  def headers_for(user, opts = {})
    opts = {:email => Sham.email, :https => false}.merge(opts)

    headers = {}
    token_coder = CF::UAA::TokenCoder.new(:audience_ids => config[:uaa][:resource_id],
      :skey => config[:uaa][:symmetric_secret],
      :pkey => nil)

    if user || opts[:admin_scope]
      user_token = token_coder.encode(
        :user_id => user ? user.guid : (rand * 1_000_000_000).ceil,
        :email => opts[:email],
        :scope => opts[:admin_scope] ? %w[cloud_controller.admin] : []
      )

      headers["HTTP_AUTHORIZATION"] = "bearer #{user_token}"
    end

    headers["HTTP_X_FORWARDED_PROTO"] = "https" if opts[:https]
    headers
  end

  def json_headers(headers)
    headers.merge({ "CONTENT_TYPE" => "application/json"})
  end

  def decoded_response(options={})
    parse(last_response.body, options)
  end

  def parse(json, options={})
    Yajl::Parser.parse(json, options)
  end

  def metadata
    decoded_response["metadata"]
  end

  def entity
    decoded_response["entity"]
  end

  def admin_user
    @admin_user ||= VCAP::CloudController::User.make(:admin => true)
  end

  def admin_headers
    @admin_headers ||= headers_for(admin_user, :admin_scope => true)
  end
end
