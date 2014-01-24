module VCAP::CloudController::Authorization
  class AllowyProvider
    Context = Struct.new(:user, :roles)

    def for_security_context(security_context)
      context = Context.new(security_context.current_user, security_context.roles)
      Authorization.new(context)
    end
  end

  class Authorization
    include Allowy::Context

    def initialize(context)
      @context = context
    end

    def authorize!(op, resource)
      if cannot?(op, resource)
        raise VCAP::Errors::NotAuthorized
      end
    end

    # Minimize interface until we actually need it
    private :can?, :cannot?

    private

    def allowy_context
      @context
    end
  end
end
