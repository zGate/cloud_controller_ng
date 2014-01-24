require "spec_helper"

module VCAP::CloudController
  describe IdentityContext::TokenProvider do
    describe "#for_auth_header" do
      subject { described_class.new(token_decoder, logger) }
      let(:token_decoder) { VCAP::UaaTokenDecoder.new({}) }
      let(:logger) { Logger.new("/dev/null") }

      def self.it_returns_nil
        it "returns empty identity context" do
          identity_context = instance_double('VCAP::CloudController::IdentityContext')
          IdentityContext::IdentityContext.should_receive(:new).
            with(nil, nil).
            and_return(identity_context)

          expect(subject.for_auth_header(token_str)).to eq(identity_context)
        end
      end

      context "when token string is nil" do
        let(:token_str) { nil }
        it_returns_nil
      end

      describe "when token string is not nil" do
        before { allow(token_decoder).to receive(:decode_token).with(token_str).and_return(token_info) }
        let(:token_str) { 'fake-token' }
        let(:token_info) { {} }

        def self.it_finds_or_creates_and_returns_user(uaa_id)
          context "when user exists in the ccdb with uaa_id (user_id/client_id)" do
            let!(:existing_user) { User.make(guid: uaa_id) }

            it "finds and returns existing user" do
              identity_context = instance_double('VCAP::CloudController::IdentityContext')
              IdentityContext::IdentityContext.should_receive(:new).
                with(existing_user, token_info).
                and_return(identity_context)

              expect(subject.for_auth_header(token_str)).to eq(identity_context)
            end
          end

          context "when user does not exist in the ccdb" do
            before { User.dataset.delete }

            context "when scope in the token includes cc admin scope" do
              before { token_info["scope"] = [Roles::CLOUD_CONTROLLER_ADMIN_SCOPE] }

              it "creates new admin user" do
                expect {
                  @identity_context = subject.for_auth_header(token_str)
                }.to change { User.count }.by(1)

                expect(@identity_context.user.guid).to eq(uaa_id)
                expect(@identity_context.user.admin).to be_true
                expect(@identity_context.user.active).to be_true
              end

              it "returns identity context with token information" do
                identity_context = instance_double('VCAP::CloudController::IdentityContext')
                IdentityContext::IdentityContext.should_receive(:new).
                  with(kind_of(User), token_info).
                  and_return(identity_context)

                expect(subject.for_auth_header(token_str)).to eq(identity_context)
              end
            end

            context "when scope in the token does not include cc admin scope" do
              before { token_info["scope"] = [] }

              it "creates non-admin user" do
                expect {
                  @identity_context = subject.for_auth_header(token_str)
                }.to change { User.count }.by(1)

                expect(@identity_context.user.guid).to eq(uaa_id)
                expect(@identity_context.user.admin).to be_false
                expect(@identity_context.user.active).to be_true
              end

              it "returns identity context with token information" do
                identity_context = instance_double('VCAP::CloudController::IdentityContext')
                IdentityContext::IdentityContext.should_receive(:new).
                  with(kind_of(User), token_info).
                  and_return(identity_context)

                expect(subject.for_auth_header(token_str)).to eq(identity_context)
              end
            end
          end
        end

        context "when user_id is present in the token" do
          before { token_info["user_id"] = "user-id" }
          it_finds_or_creates_and_returns_user("user-id")
        end

        context "when client_id is present in the token" do
          before { token_info["client_id"] = "client-id" }
          it_finds_or_creates_and_returns_user("client-id")
        end

        context "when there is no user_id or client_id" do
          it_returns_nil

          it "does not create any new users" do
            expect {
              subject.for_auth_header(token_str)
            }.to_not change { User.count }
          end
        end

        context "when the token is invalid" do
          before { token_decoder.stub(:decode_token).and_raise(exception_class) }

          %w[SignatureNotSupported SignatureNotAccepted InvalidSignature InvalidTokenFormat InvalidAudience].each do |exception|
            context "when decoding fails with #{exception}" do
              let(:exception_class) { "CF::UAA::#{exception}".constantize }

              it_returns_nil

              it "should log to warn" do
                logger.should_receive(:warn).with(/^Invalid bearer token: .+/)
                subject.for_auth_header(token_str)
              end
            end
          end

          context "when auth token is expired" do
            let(:exception_class) { CF::UAA::TokenExpired }

            it_returns_nil

            it "should log to info" do
              logger.should_receive(:info).with(/^Token expired$/)
              subject.for_auth_header(token_str)
            end
          end
        end
      end
    end
  end
end
