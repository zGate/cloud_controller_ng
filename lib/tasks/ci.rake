namespace :ci do
  task :spec, [:threads, :format, :seed] do |_, args|
    sh "bundle exec parallel_rspec spec -s 'integration|acceptance' -n #{args[:threads]} -o '--format #{args[:format]} --seed #{args[:seed]}'"
  end

  task :api_docs, [:threads, :format, :seed] do |_, args|
    sh "bundle exec parallel_rspec spec/api -s 'integration|acceptance' -n #{args[:threads]} -o '--format #{args[:format]} --seed #{args[:seed]}'"
  end
end
