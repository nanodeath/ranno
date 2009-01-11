require 'ranno'

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
  def self.time_it(method_name)
    if(annotation_args.include? :before)
      @timer = Time.now
    elsif(annotation_args.include? :after)
      puts "Time It: #{method_name} took #{Time.now - @timer}s"
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
end

m = MyMainClass.new
[:yourmom, :yourdad, :yourgrammy, :yoursister, :counter].each do |method|
  m.send(method)
end