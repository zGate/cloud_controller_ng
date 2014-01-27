module VCAP::CloudController::Authorization
  class OpenProvider
    def initialize(expected_identity_context)
      @expected_identity_context = expected_identity_context
    end

    def for_identity_context(identity_context)
      if @expected_identity_context == identity_context
        OpenAuthorization.new(@allowed_op, @allowed_res)
      else
        raise ArgumentError, "identity_context must match expected identity context"
      end
    end

    def disallow_access(operation, resource)
      @allowed_op = operation || raise(ArgumentError, "operation must not be nil")
      @allowed_res = resource || raise(ArgumentError, "resource must not be nil")
    end
  end

  class OpenAuthorization
    def initialize(disallowed_op, disallowed_res)
      @disallowed_op = disallowed_op
      @disallowed_res = disallowed_res
    end

    def authorize!(op, resource)
      if op == @disallowed_op && resource == @disallowed_res
        raise VCAP::Errors::NotAuthorized
      end
    end
  end
end
