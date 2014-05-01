require "spec_helper"
require "jobs/runtime/restage"
require "models/runtime/space"

module VCAP::CloudController
  module Jobs::Runtime
    describe Restage do
      describe "#perform" do
        let(:app) { double(App, guid: "GUID") }

        subject(:job) { Restage.new(app.guid) }

        context "restaging an app" do
          before do
            allow(App).to receive(:find).with(app.guid).and_return(app)
          end

          it "stops the app" do
            expect(app).to receive(:stop!).ordered
            expect(app).to receive(:mark_for_restaging).ordered
            expect(app).to receive(:start!).ordered

            job.perform
          end
        end

        it "knows its job name" do
          expect(job.job_name_in_configuration).to equal(:restage)
        end
      end
    end
  end
end
