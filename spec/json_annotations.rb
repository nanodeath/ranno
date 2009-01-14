require 'json'

module JSONAnnotations
  extend Ranno::Annotations

  class_annotation :json_arg do |method_name|
    @json_args ||= []
    @json_args << method_name
  end
end



module JSON
  def self.included(klass)
    if !klass.included_modules.include? Ranno::Base
      klass.class_eval do
        include Ranno::Base
      end
    end
    klass.class_eval do
      def self.set_json_arg key, value
        @json_args << [key, value]
      end
    end
    
    klass.class.class_eval do
      attr_reader :json_args
    end
  end

  def to_json
    def parse_value(v)
      if v.is_a? Symbol
        instance_eval(v.to_s)
      elsif v.is_a? Array
        v.collect do |e|
          parse_value(e)
        end
      elsif v.is_a? String
        v
      else
        nil
      end
    end

    self.class.json_args.inject({}) do
      |memo, arg|
      value = parse_value(arg)
      if(arg.is_a? Symbol)
        memo[arg] = value
      elsif (arg.is_a? Array and arg.length == 2)
        memo[value[0]] = value[1]
      end
      memo
    end.to_json
  end
end