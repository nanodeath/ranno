require File.dirname(__FILE__) + '/spec_helper'

module ClassAnnotations
  extend Ranno::Annotations

  class_annotation :fie do |method_name|
    @fie_list ||= []
    @fie_list << method_name
  end

  instance_annotation :play do |method_name|
    puts method_name + " wants to play!"
  end
end

class TestClass1
  include Ranno::Base
  use_annotations ClassAnnotations

  fie
  def say_hello
    puts "hello"
  end

  def self.retrieved_fied
    @fie_list
  end
end

class TestClass2
  include Ranno::Base
  use_annotations ClassAnnotations

  fie
  def say_hello
    puts "hello"
  end

  fie
  def say_goodbye
    puts "goodbye"
  end

  def self.retrieved_fied
    @fie_list
  end
end

class ParentClass
  
end

class ChildClass < ParentClass

end

describe "ranno" do
  describe 'Class Annotations' do
    it "should execute class annotations" do
      TestClass1.retrieved_fied.should eql([:say_hello])
    end

    it "should execute multiple methods with teh same class annotations" do
      TestClass2.retrieved_fied.should eql([:say_hello, :say_goodbye])
    end
  end
end

