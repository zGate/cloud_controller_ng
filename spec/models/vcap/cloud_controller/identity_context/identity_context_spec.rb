require "spec_helper"

module VCAP::CloudController
  describe IdentityContext::IdentityContext do
    describe "#user" do
      it "returns user if user is provided" do
        user = instance_double('VCAP::CloudController::User')
        subject = described_class.new(user, nil)
        expect(subject.user).to eq(user)
      end

      it "returns nil if user is not provided" do
        subject = described_class.new(nil, nil)
        expect(subject.user).to be_nil
      end
    end

    describe "#roles" do
      it "returns roles if token is provided" do
        subject = described_class.new(nil, {"scope" => []})
        expect(subject.roles).to be_an_instance_of(Roles)
      end

      it "returns roles if token is empty" do
        subject = described_class.new(nil, {})
        expect(subject.roles).to be_an_instance_of(Roles)
      end

      it "returns roles if token is not provided" do
        subject = described_class.new(nil, nil)
        expect(subject.roles).to be_an_instance_of(Roles)
      end
    end

    describe "#admin?" do
      it "returns true if token includes cc admin scope" do
        subject = described_class.new(nil, {"scope" => [Roles::CLOUD_CONTROLLER_ADMIN_SCOPE]})
        expect(subject.admin?).to be(true)
      end

      it "returns false if token does not include cc admin scope" do
        subject = described_class.new(nil, {"scope" => ["non-admin-scope"]})
        expect(subject.admin?).to be(false)
      end

      it "returns false if token does not have scopes" do
        subject = described_class.new(nil, {})
        expect(subject.admin?).to be(false)
      end

      it "returns false if token is nil" do
        subject = described_class.new(nil, nil)
        expect(subject.admin?).to be(false)
      end
    end
  end
end
