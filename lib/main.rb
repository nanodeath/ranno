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

  instance_annotation :before
  def self.time_it(method_name, args)
    puts args.inspect
  end
end

class MyMainClass
  include Ranno::Base

  use_annotations MyMainClassAnnotations

  final
  def yourmom
    puts "this method shouldn't be overridden"
  end

  final
  def yourdad
    puts "hahaha"
  end

  logger
  def yourgrammy
    puts "Eh????"
  end

  logger
  note 'is hot'
  def yoursister

  end

#  time_it
#  def counter
#    1.upto(10000) do
#      # nothing
#    end
#  end
end

MyMainClass.new.yourgrammy
#MyMainClass.new.counter