module Flamingo
  module Daemon
    class WaderProcess < ChildProcess
      def register_signal_handlers
        trap("TERM") { stop }
        trap("INT")  { stop }
      end

      def load_config
        YAML.load(ERB.new(IO.read(Flamingo::CONFIG_FILE)).result)
      end

      def run
        register_signal_handlers
        $0 = 'wader (flamingod)'
        config      = load_config
        screen_name = config["username"]
        password    = config["password"]
        stream      = Stream.get(config["stream"])

        @wader = Flamingo::Wader.new(screen_name,password,stream)
        Flamingo.logger.info "Starting wader"
        puts "Starting wader on #{Process.pid} under #{Process.ppid}"
        @wader.run
      end

      def stop
        puts "Stopping wader on #{Process.pid}"
        @wader.stop
      end
    end
  end
end
