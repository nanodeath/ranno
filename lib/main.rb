require 'ranno'

# Consider this the "sample application" against which you can learn how the library works,
# but it's not the de facto specs by any means.

module MyMainClassAnnotations
  extend Ranno::Annotations

  class_annotation
  def self.final(method_name)
    puts "Final: I want #{method_name} to be final..."
    # http://www.thesorensens.org/2006/10/06/final-methods-in-ruby-prevent-method-override
  end

  class_annotation
  def self.note(method_name, n)
    puts "Note: #{method_name} is '#{n}'"
  end

  instance_annotation
  def self.logger(method_name)
    puts "Logger: #{method_name} is about to be called"
  end

  instance_annotation :before, :after
  # If :ignore_recursion is true, don't print unless the stack is empty
  def self.time_it(method_name, opts={})
    opts[:ignore_recursion] = false unless opts.key? :ignore_recursion

    @@timer ||= {}
    @@timer[method_name] ||= []

    if(annotation_args.include? :before)
      @@timer[method_name].push(Time.now)
    elsif(annotation_args.include? :after)
      time_taken = Time.now - @@timer[method_name].pop
      if !opts[:ignore_recursion] || @@timer[method_name].size == 0
        puts "Time It: #{method_name} took #{time_taken}s"
      end
    end
  end

  instance_annotation
  def self.prefix(method_name, message)
    print message.gsub('--method--', method_name.to_s)
  end
end

class MyMainClass
  include Ranno::Base

  use_annotations MyMainClassAnnotations

  #  final
  prefix "--method-- says: "
  def yourmom
    puts "You don't get desert until you finish your dinner!"
  end

  final
  prefix "--method-- says: "
  def yourdad
    puts "Do what your mother says."
  end

  logger
  prefix "--method-- says: "
  def yourgrammy
    puts "Is someone talking??"
  end

  logger
  note 'is hot'
  prefix "--method-- says: "
  def yoursister
    puts "Shut up, dorkface."
  end

  time_it
  def counter
    1.upto(1000000) do
      # nothing
    end
  end

  @@fibo = {}
  
  time_it :ignore_recursion => true
  def smart_fibonacci(n)
    raise if n < 0
    return @@fibo[n] if @@fibo.key? n
    case n
    when 0
      @@fibo[n] = 0
    when 1
      @@fibo[n] = 1
    else
      @@fibo[n - 1] = smart_fibonacci(n - 1)
      @@fibo[n - 2] = smart_fibonacci(n - 2)
      @@fibo[n - 1] + @@fibo[n - 2]
    end
  end

  time_it :ignore_recursion => true
  def dumb_fibonacci(n)
    raise if n < 0
    case n
    when 0
      0
    when 1
      1
    else
      dumb_fibonacci(n - 1) + dumb_fibonacci(n - 2)
    end
  end

  def print_timer
     puts "the timer says #{MyMainClassAnnotations.timer}"
  end
end

m = MyMainClass.new
[:yourmom, :yourdad, :yourgrammy, :yoursister, :counter, :print_timer].each do |method|
  m.send(method)
end

m.dumb_fibonacci(15)
m.smart_fibonacci(15)
