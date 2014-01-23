module VCAP::CloudController
  class TokenToUserFinder
    def initialize(token_decoder, logger)
      @token_decoder = token_decoder
      @logger = logger
    end

    def find(auth_token)
      user, token = nil

      if token_info = decode_token(auth_token)
        if uaa_id = token_info["user_id"] || token_info["client_id"]
          user = User.find(:guid => uaa_id.to_s) || create_user(uaa_id, token_info)
          token = token_info
        end
      end
      [user, token]
    end

    private

    def decode_token(auth_token)
      @token_decoder.decode_token(auth_token).tap do |info|
        @logger.info("Token received from the UAA #{info.inspect}")
      end
    rescue CF::UAA::TokenExpired
      @logger.info("Token expired")
      return nil
    rescue CF::UAA::DecodeError, CF::UAA::AuthError => e
      @logger.warn("Invalid bearer token: #{e.inspect} #{e.backtrace}")
      return nil
    end

    def create_user(uaa_id, token)
      User.create(
        guid: uaa_id,
        admin: VCAP::CloudController::Roles.new(token).admin?,
        active: true,
      )
    end
  end
end
