module Flamingo
  class Config < Hash

    def self.load(file)
      new(YAML.load(IO.read(file)))
    end

    def initialize(hash={})
      replace hash
    end

    def method_missing(name,*args,&block)
      if name.to_s =~ /(.+)=$/
        self[$1] = *args
      else
        value = self[name.to_s]
        if value.is_a?(Hash)
          self.class.new(value)
        elsif value.nil? || empty_config?(value)
          if !args.empty?
            # Return a default if the value isn't set and there's an argument
            args.length == 1 ? args[0] : args
          elsif block_given?
            # Run the block to get the default value
            yield
          else
            # Return back a config object
            value = self.class.new
            self[name.to_s] = value
            value
          end
        else
          value
        end
      end
    end

    def respond_to?(name)
      true
    end

    def present?
      not blank?
    end

    def slice *keys
      hash = self.class.new
      keys.each{|k| hash[k] = self[k.to_s] if has_key?(k.to_s) }
      hash
    end

    private
      def empty_config?(value)
        value.is_a?(self.class) && value.empty?
      end

  end
end
