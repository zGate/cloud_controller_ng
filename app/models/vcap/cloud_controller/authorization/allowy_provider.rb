module VCAP::CloudController::Authorization
  class AllowyProvider
    def for_identity_context(identity_context)
      Authorization.new(identity_context)
    end
  end

  class Authorization
    include Allowy::Context

    def initialize(identity_context)
      @identity_context = identity_context
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
      @identity_context
    end
  end
end
