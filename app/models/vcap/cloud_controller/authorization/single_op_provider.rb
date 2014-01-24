module VCAP::CloudController::Authorization
  class SingleOpProvider
    def for_security_context(sec_con)
      raise ArgumentError, "security_context must not be nil" unless sec_con
      SingleOpAuthorization.new(@allowed_op, @allowed_res)
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
