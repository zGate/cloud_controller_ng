module VCAP::CloudController::Authorization
  class SingleOpProvider
    def initialize(expected_identity_context)
      @expected_identity_context = expected_identity_context
    end

    def for_identity_context(identity_context)
      if @expected_identity_context == identity_context
        SingleOpAuthorization.new(@allowed_op, @allowed_res)
      else
        raise ArgumentError, "identity_context must match expected identity context"
      end
    end

    def allow_access(operation, resource)
      @allowed_op = operation || raise(ArgumentError, "operation must not be nil")
      @allowed_res = resource || raise(ArgumentError, "resource must not be nil")
    end
  end

  class SingleOpAuthorization
    def initialize(allowed_op, allowed_res)
      @allowed_op = allowed_op
      @allowed_res = allowed_res
    end

    def authorize!(op, resource)
      if !(op == @allowed_op && resource == @allowed_res)
        raise VCAP::Errors::NotAuthorized
      end
    end
  end
end
