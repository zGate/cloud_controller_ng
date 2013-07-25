app = lambda do |env|
  message = ENV['MAINTENANCE_MESSAGE'] || 'We will be back shortly.'
  body = %Q[{message:"#{message}"}]
  [503, { "Content-Type" => "application/json", "Content-Length" => body.length.to_s }, [body]]
end

run app
