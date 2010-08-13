module Flamingo
  class Stream

    VERSION = 1

    RESOURCES = HashWithIndifferentAccess.new(
      :filter   => "statuses/filter",
      :firehose => "statuses/firehose",
      :retweet  => "statuses/retweet",
      :sample   => "statuses/sample"
    )

    STREAM_DEFAULTS = {
      :ssl        => true,
      :user_agent => "Flamingo/0.1",
      :method     => 'GET',
      :proxy      => nil,
    }

    class << self
      def get(name)
        new(name,StreamParams.new(name))
      end
    end

    attr_accessor :name, :params

    def initialize(name, params)
      self.name = name
      self.params = params
    end

    def connect(options)
      conn_opts = STREAM_DEFAULTS.
        merge(Flamingo.config.slice(*STREAM_DEFAULTS.keys)).
        merge(:path=> path, :params => params.all ).
        merge(options)
      Twitter::JSONStream.connect(conn_opts)
    end

    def path
      "/#{VERSION}/#{resource}.json"
    end

    def resource
      RESOURCES[name.to_sym]
    end

    def to_json
      ActiveSupport::JSON.encode(
        :name=>name,:resource=>resource,:params=>params.all
      )
    end
  end
end
