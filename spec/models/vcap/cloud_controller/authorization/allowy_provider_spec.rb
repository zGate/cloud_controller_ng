require "spec_helper"

describe VCAP::CloudController::Authorization::AllowyProvider do
  describe "#authorize!" do
    subject { described_class.new.for_security_context(sec_con) }
    let(:sec_con) { class_double('VCAP::CloudController::SecurityContext', current_user: user, roles: roles) }

    let(:user) { double('user') }
    let(:roles) { double('roles') }
    let(:resource) { TestObj.new }

    class TestObjAccess
      include Allowy::AccessControl
      cattr_reader :last_context

      def allowed_op?(_)
        @@last_context = context
        true
      end

      def disallowed_op?(_)
        @@last_context = context
        false
      end
    end

    class TestObj; end

    context "when operation is allowed" do
      it "does not raise NotAuthorized error" do
        expect {
          subject.authorize!(:allowed_op, resource)
        }.to_not raise_error
      end

      it "can use provided security context when evaluating access" do
        subject.authorize!(:allowed_op, resource)
        expect(TestObjAccess.last_context.user).to eq(user)
        expect(TestObjAccess.last_context.roles).to eq(roles)
      end
    end

    context "when operation is not allowed" do
      it "raises NotAuthorized error" do
        expect {
          subject.authorize!(:disallowed_op, resource)
        }.to raise_error(VCAP::Errors::NotAuthorized)
      end

      it "can use provided security context when evaluating access" do
        subject.authorize!(:disallowed_op, resource) rescue nil
        expect(TestObjAccess.last_context.user).to eq(user)
        expect(TestObjAccess.last_context.roles).to eq(roles)
      end
    end
  end
end
