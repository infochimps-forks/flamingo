require 'wukong'

module Flamingo
  class Wader
    attr_accessor :screen_name, :password, :stream, :connection

    def initialize(screen_name,password,stream)
      self.screen_name = screen_name
      self.password = password
      self.stream = stream
    end

    #
    # The main EventMachine run loop
    #
    # Start the stream listener (using twitter-stream, http://github.com/voloko/twitter-stream)
    # Listen for responses and errors;
    #   dispatch each for later handling
    #
    def run
      EventMachine::run do
        self.connection = stream.connect(:auth=>"#{screen_name}:#{password}")
        Flamingo.logger.info("Listening on stream: #{stream.path}")

        chunk_file = Wukong::Store::ChhChunkedFlatFileStore.new( { :rootdir => '/home/chris/infochimps', :chunktime => 10 , :filemode => 'w'} )
  
        EventMachine.add_periodic_timer(4*60) { chunk_file.new_chunk }

        connection.each_item do |event_json|
          chunk_file << event_json
          chunk_file.flush
          dispatch_event(event_json)
        end

        connection.on_error do |message|
          dispatch_error(:generic,message)
        end

        connection.on_reconnect do |timeout, retries|
          dispatch_error(:reconnection,
            "Will reconnect after #{timeout}. Retry \##{retries}",
            {:timeout=>timeout,:retries=>retries}
          )
        end

        connection.on_max_reconnects do |timeout, retries|
          dispatch_error(:fatal,
            "Failed to reconnect after #{retries} retries",
            {:timeout=>timeout,:retries=>retries}
          )
        end
      end
    end

    def stop
      connection.stop
      EM.stop
    end

    protected
      def dispatch_event(event_json)
        Flamingo.logger.debug "Wader dispatched event"
        ##CHH Disabled ##  Resque.enqueue(Flamingo::DispatchEvent, event_json)
        # Resque.enqueue(Flamingo::DispatchEvent, {:src => "flamingo:#{stream.name}"}, event_json)
      end

      def dispatch_error(type,message,data={})
        Flamingo.logger.error "Received error: #{message}"
        ##CHH Disabled ## Resque.enqueue(Flamingo::DispatchError, type, message, data)
      end
  end
end
