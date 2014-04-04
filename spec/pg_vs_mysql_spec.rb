require "spec_helper"
require "repositories/runtime/app_usage_event_repository"

module VCAP::CloudController
  describe "pg vs mysql" do
    it "works" do
      expect {
        AppFactory.make
      }.to change { AppUsageEvent.count }.from(0).to(1)
    end
  end
end
