require "spec_helper"

module VCAP::CloudController
  describe VCAP::CloudController::Droplet, type: :model do
    it "should be there" do
      VCAP::CloudController::Droplet.should be
    end

    it_behaves_like "a CloudController model", {
      required_attributes: [:app, :droplet_hash]
    }
  end
end