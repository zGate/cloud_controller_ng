# Ideally we would require 'rspec/rails'; however,
# we have integration/controller/etc tests that do not work
# properly when all rspec-rails example groups are loaded.
require 'rspec/rails/adapters'
require 'rspec/rails/example/rails_example_group'
require 'rspec/rails/example/request_example_group'

RSpec.configure do |c|
  def c.escaped_path(*parts)
    Regexp.compile(parts.join('[\\\/]') + '[\\\/]')
  end

  request_path_regex = c.escaped_path(%w[spec requests])

  c.include(RSpec::Rails::RequestExampleGroup, {
    :type          => :request,
    :example_group => lambda { |example_group, metadata|
      metadata[:type].nil? && request_path_regex =~ example_group[:file_path]
    }
  })
end
