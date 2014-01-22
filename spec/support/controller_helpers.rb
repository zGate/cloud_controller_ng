require File.expand_path("../controller_helpers/nginx_upload", __FILE__)

module ControllerHelpers
  include VCAP::CloudController

  HTTPS_ENFORCEMENT_SCENARIOS = [
    {:protocol => "http",  :config_setting => nil, :user => "user",  :success => true},
    {:protocol => "http",  :config_setting => nil, :user => "admin", :success => true},
    {:protocol => "https", :config_setting => nil, :user => "user",  :success => true},
    {:protocol => "https", :config_setting => nil, :user => "admin", :success => true},

    # Next with https_required
    {:protocol => "http",  :config_setting => :https_required, :user => "user",  :success => false},
    {:protocol => "http",  :config_setting => :https_required, :user => "admin", :success => false},
    {:protocol => "https", :config_setting => :https_required, :user => "user",  :success => true},
    {:protocol => "https", :config_setting => :https_required, :user => "admin", :success => true},

    # Finally with https_required_for_admins
    {:protocol => "http",  :config_setting => :https_required_for_admins, :user => "user",  :success => true},
    {:protocol => "http",  :config_setting => :https_required_for_admins, :user => "admin", :success => false},
    {:protocol => "https", :config_setting => :https_required_for_admins, :user => "user",  :success => true},
    {:protocol => "https", :config_setting => :https_required_for_admins, :user => "admin", :success => true}
  ]

  def app
    token_decoder = VCAP::UaaTokenDecoder.new(config[:uaa])
    klass = Class.new(VCAP::CloudController::Controller)
    klass.use(NginxUpload)
    klass.new(config, token_decoder)
  end

  shared_examples "return a vcap rest encoded object" do
    it "should return a metadata hash in the response" do
      metadata.should_not be_nil
      metadata.should be_a_kind_of(Hash)
    end

    it "should return an id in the metadata" do
      metadata["guid"].should_not be_nil
      # used to check if the id was an integer here, but now users
      # use uaa based ids, which are strings.
    end

    it "should return a url in the metadata" do
      metadata["url"].should_not be_nil
      metadata["url"].should be_a_kind_of(String)
    end

    it "should return an entity hash in the response" do
      entity.should_not be_nil
      entity.should be_a_kind_of(Hash)
    end
  end

  def resource_match_request(verb, path, matches, non_matches)
    user = User.make(:admin => true, :active => true)
    req = Yajl::Encoder.encode(matches + non_matches)
    send(verb, path, req, json_headers(headers_for(user)))
    last_response.status.should == 200
    resp = Yajl::Parser.parse(last_response.body)
    resp.should == matches
  end
end
