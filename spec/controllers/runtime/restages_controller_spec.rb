require "spec_helper"

module VCAP::CloudController
  describe RestagesController, type: :controller do
    describe "POST /v2/apps/:id/restage" do
      let(:package_state) { "STAGED" }

      before do
        @app = AppFactory.make(:package_hash => "abc", :package_state => package_state)
      end

      subject(:restage_request) { post("/v2/apps/#{@app.guid}/restage", {}, headers_for(account)) }

      context "as a user" do
        let(:account) {  make_user_for_space(@app.space) }

        it "should return 403" do
          restage_request
          expect(last_response.status).to eq(403)
        end
      end

      context "as a developer" do
        let(:account) { make_developer_for_space(@app.space) }

        it "returns a success response" do
          restage_request
          expect(last_response.status).to eq(201)
        end

        it "provides the information to poll the job" do
          restage_request
          expect(last_response.body).to match("v2/jobs")
          expect(last_response.body).to match("queued")
        end

        it "restages asynchronously" do
          expect {
            restage_request
          }.to change {
            Delayed::Job.count
          }.by(1)

          job = Delayed::Job.last

          expect(job.handler).to include("Jobs::Runtime::Restage")
          expect(job.handler).to include(@app.guid)
          expect(job.queue).to eq("cc-generic")
          expect(job.guid).not_to be_nil
        end

        context "when the app is pending to be staged" do
          before do
            @app.package_state = "PENDING"
            @app.save
          end

          it "returns '170002 NotStaged'" do
            restage_request

            expect(last_response.status).to eq(400)
            parsed_response = Yajl::Parser.parse(last_response.body)
            expect(parsed_response["code"]).to eq(170002)
          end
        end
      end
    end
  end
end
