require "spec_helper"

describe RailsController do
  it "returns 200" do
    get "/rails"
    last_response.status.should == 200
    last_response.body.should == "ok"
  end
end
