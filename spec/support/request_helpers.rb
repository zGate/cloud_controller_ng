require "models/vcap/cloud_controller/identity_context/preset_provider"
require "models/vcap/cloud_controller/identity_context/identity_context"

module RequestHelpers
  def app
    Rails.application.tap do |app|
      app.cc_config = config
      app.reset_sinatra_cc_app
    end
  end
end

module RequestDependencyLocatorHelpers
  def with_dependency_locator
    let(:dependency_locator) { CloudController::DependencyLocator.instance }
  end

  def with_preset_identity_context
    before do
      icp = VCAP::CloudController::IdentityContext::PresetProvider.new(preset_headers, preset_identity_context)
      dependency_locator.stub(:identity_context_provider).with(no_args).and_return(icp)
    end
    let(:preset_headers) { {"HTTP_AUTHORIZATION" => "some-token"} }
    let(:preset_identity_context) { VCAP::CloudController::IdentityContext::PresetIdentityContext.new }
  end

  def with_single_op_authorization
    before { dependency_locator.stub(:authorization_provider).with(no_args).and_return(single_op_authorization) }
    let(:single_op_authorization) { VCAP::CloudController::Authorization::SingleOpProvider.new(preset_identity_context) }
  end
end
