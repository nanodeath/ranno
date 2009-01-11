# To change this template, choose Tools | Templates
# and open the template in the editor.

puts "Hello World"

require 'ranno'

module MyMainClassAnnotations
  extend Ranno::Annotations

  class_annotation 'foo'
  def self.final(method_name, hah=nil)
    puts "[#{method_name} is now final]"
#    puts "also args are #{opts.inspect}"
  end

  class_annotation
  def self.note(method_name, note)
    puts "Note about #{method_name}: #{note}"
  end

  instance_annotation :before
  def self.logger(method_name)
    puts "note to self: #{method_name} was just called"
  end
end

class MyMainClass
  include Ranno::Base

  use_annotations MyMainClassAnnotations

  final
  def yourmom
    puts "this method shouldn't be overridden"
  end

  final 'foo'
  def yourdad
    puts "hahaha"
  end

  logger
  def yourgrammy
    puts "dood"
  end

  def yoursister

  end

  final
  def yourmother

  end

  def one1

  end

  def one3

  end

  def one2

  end


end

MyMainClass.new.yourgrammy