require "spec_helper"

describe VCAP::CloudController::RequestSchemeVerifier do
  describe "#verify" do
    subject { described_class.new(config) }
    let(:config) { {} }

    let(:user) { instance_double('VCAP::CloudController::User') }
    let(:request) { instance_double('Rack::Request') }
    let(:security_context) { class_double('VCAP::CloudController::SecurityContext') }

    def self.it_raises_not_authorized_error
      it "does raise NotAuthorized error" do
        expect {
          subject.verify(request, security_context)
        }.to raise_error(VCAP::CloudController::Errors::NotAuthorized)
      end
    end

    def self.it_does_not_raise_not_authorized_error
      it "does not raise NotAuthorized error" do
        expect { subject.verify(request, security_context) }.to_not raise_error
      end
    end

    def self.it_verifies_https
      context "when https_required is set to true in the config" do
        before { config[:https_required] = true }

        context "when request scheme is https"  do
          before { request.stub(:scheme).and_return("https") }
          it_does_not_raise_not_authorized_error
        end

        context "when request scheme is not https" do
          before { request.stub(:scheme).and_return("ftp") }
          it_raises_not_authorized_error
        end
      end

      context "when https_required is set to false in the config" do
        before { config[:https_required] = false }

        context "when request scheme is https" do
          before { request.stub(:scheme).and_return("https") }
          it_does_not_raise_not_authorized_error
        end

        context "when request scheme is not https" do
          before { request.stub(:scheme).and_return("ftp") }
          it_does_not_raise_not_authorized_error
        end
      end
    end

    def self.it_does_not_verify_https
      context "when https_required is set to true in the config" do
        before { config[:https_required] = true }

        context "when request scheme is https"  do
          before { request.stub(:scheme).and_return("https") }
          it_does_not_raise_not_authorized_error
        end

        context "when request scheme is not https" do
          before { request.stub(:scheme).and_return("ftp") }
          it_does_not_raise_not_authorized_error
        end
      end

      context "when https_required is set to false in the config" do
        before { config[:https_required] = false }

        context "when request scheme is https" do
          before { request.stub(:scheme).and_return("https") }
          it_does_not_raise_not_authorized_error
        end

        context "when request scheme is not https" do
          before { request.stub(:scheme).and_return("ftp") }
          it_does_not_raise_not_authorized_error
        end
      end
    end

    def self.it_verifies_https_for_admins
      context "when https_required_for_admins is set to true in the config" do
        before { config[:https_required_for_admins] = true }

        context "when request scheme is https"  do
          before { request.stub(:scheme).and_return("https") }
          it_does_not_raise_not_authorized_error
        end

        context "when request scheme is not https" do
          before { request.stub(:scheme).and_return("ftp") }
          it_raises_not_authorized_error
        end
      end

      context "when https_required_for_admins is set to false in the config" do
        before { config[:https_required_for_admins] = false }

        context "when request scheme is https" do
          before { request.stub(:scheme).and_return("https") }
          it_does_not_raise_not_authorized_error
        end

        context "when request scheme is not https" do
          before { request.stub(:scheme).and_return("ftp") }
          it_does_not_raise_not_authorized_error
        end
      end
    end

    def self.it_does_not_verify_https_for_admins
      context "when https_required_for_admins is set to true in the config" do
        before { config[:https_required_for_admins] = true }

        context "when request scheme is https"  do
          before { request.stub(:scheme).and_return("https") }
          it_does_not_raise_not_authorized_error
        end

        context "when request scheme is not https" do
          before { request.stub(:scheme).and_return("ftp") }
          it_does_not_raise_not_authorized_error
        end
      end

      context "when https_required_for_admins is set to false in the config" do
        before { config[:https_required_for_admins] = false }

        context "when request scheme is https" do
          before { request.stub(:scheme).and_return("https") }
          it_does_not_raise_not_authorized_error
        end

        context "when request scheme is not https" do
          before { request.stub(:scheme).and_return("ftp") }
          it_does_not_raise_not_authorized_error
        end
      end
    end

    context "when security context has a user" do
      before { security_context.stub(:current_user).and_return(user) }

      context "when security context is not an admin" do
        before { security_context.stub(:admin?).and_return(false) }
        it_verifies_https
        it_does_not_verify_https_for_admins
      end

      context "when security context is an admin" do
        before { security_context.stub(:admin?).and_return(true) }
        it_verifies_https
        it_verifies_https_for_admins
      end
    end

    context "when security context does not have a user" do
      before { security_context.stub(:current_user).and_return(nil) }

      context "when security context is an admin" do
        before { security_context.stub(:admin?).and_return(false) }
        it_does_not_verify_https
        it_does_not_verify_https_for_admins
      end

      context "when security context is an admin" do
        before { security_context.stub(:admin?).and_return(true) }
        it_verifies_https
        it_verifies_https_for_admins
      end
    end
  end
end
