require File.dirname(__FILE__) + '/spec_helper'

module ClassAnnotations
  extend Ranno::Annotations

  class_annotation :fie do |method_name|
    @fie_list ||= []
    @fie_list << method_name
  end

  instance_annotation :counter, :hook => :after do |method_name, hook|
    @counter ||= {}
    @counter[method_name] = 0 unless @counter.key? method_name
    @counter[method_name] += 1
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

  counter
  def count_me_in
    
  end

  def get_count_of sym
#    puts "getting counter in #{self} (#{@counter})"
    @counter[sym]
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

  describe 'Instance Annotations' do
    it "should work" do
      t2 = TestClass2.new
      4.times { t2.count_me_in }
      t2.get_count_of(:count_me_in).should equal(4)
    end
  end
end

