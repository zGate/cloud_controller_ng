argv = ARGV.dup
runner = VCAP::CloudController::Runner.new(argv)
pid runner.config[:pid_filename]

worker_processes runner.config[:web_workers] || 4 # amount of unicorn workers to spin up
timeout 30         # restarts workers that hang for 30 seconds

preload_app true

if runner.config[:nginx][:use_nginx]
  listen_on = runner.config[:nginx][:instance_socket]
else
  listen_on = "#{runner.config[:bind_address]}:#{runner.config[:port]}"
end

puts "Listening on #{listen_on}"
listen listen_on


GC.respond_to?(:copy_on_write_friendly=) and
    GC.copy_on_write_friendly = true

before_fork do |server,worker|
end

after_fork do |server,worker|
  if defined?(EventMachine)
    unless EventMachine.reactor_running? && EventMachine.reactor_thread.alive?
      puts "Stopping event machine"
      if EventMachine.reactor_running?
        EventMachine.stop_event_loop
        EventMachine.release_machine
        EventMachine.instance_variable_set("@reactor_running",false)
      end
      puts "Starting EM"
      Thread.new { EventMachine.run }
    end
  end

  #Signal.trap("INT") { EventMachine.stop }
  #Signal.trap("TERM") { EventMachine.stop }

  VCAP::CloudController::Runner.new(argv, runner.config_file).post_fork!(server)
end