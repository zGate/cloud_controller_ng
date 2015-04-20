require 'net/http'
require 'json'
require 'fog'

def push_docs_to_s3(travis_build_id)
  storage = Fog::Storage.new(
    provider: 'AWS',
    aws_access_key_id: ENV['AWS_ACCESS_KEY_ID'],
    aws_secret_access_key: ENV['AWS_SECRET_ACCESS_KEY']
  )

  docs_bucket_name = "cc-api-docs"
  rc_dir_name = "release-candidate"

  puts 'Copying API docs to release-candidate bucket'
  source_docs = storage.directories.get(docs_bucket_name, prefix: travis_build_id)
  source_docs.files.each do |file|
    new_file_key = file.key.gsub(/#{travis_build_id}/, rc_dir_name)
    file.copy(docs_bucket_name, new_file_key)
  end
end

commit = `git rev-parse HEAD`.strip
puts "cloud_controller_ng commit: #{commit}"

uri = URI("https://api.travis-ci.org/repos/cloudfoundry/cloud_controller_ng/builds")
puts "Fetching travis builds from #{uri}"
http = Net::HTTP.new(uri.host, uri.port)
http.use_ssl = true

req = Net::HTTP::Get.new(uri.request_uri)
result = http.request(req)

builds = JSON.parse(result.body)
builds.select! do |build|
  build['commit'] == commit
end

unless builds.empty?
  travis_build_id = builds.first['id']
  puts "Travis build id: #{travis_build_id}"
end

push_docs_to_s3(travis_build_id)
