require File.dirname(__FILE__) + '/spec_helper'
require File.dirname(__FILE__) + '/user'

module ClassAnnotations
  extend Ranno::Annotations

  class_annotation :fie do |method_name|
    @fie_list ||= []
    @fie_list << method_name
  end

  class_annotation :foo do |method_name|
    @foo_list ||= []
    @foo_list << method_name
  end
end

module InstanceAnnotations
  extend Ranno::Annotations
  
  # Count the total number of times method_name has been executed (in this class)
  instance_annotation :counter, :hook => :before do |method_name|
    @counter ||= {}
    @counter[method_name] = 0 unless @counter.key? method_name
    @counter[method_name] += 1
  end

  # Record the amount of time it takes a method to execute and store that value
  # in @timer_result[method_name]
  instance_annotation :timer, :hook => :both do |method_name, opts|
    @timer ||= {}
    @timer[method_name] ||= []
    opts ||= {}
    
    if(ranno_params[:hook] == :before)
      @timer[method_name].push(Time.now)
    else
      time_taken = Time.now - @timer[method_name].pop
      if (!opts[:ignore_recursion] || @timer[method_name].size == 0)
        if opts[:verbose]
          puts "Time It: #{method_name} took #{time_taken}s"
        end
        @timer_result ||= {}
        @timer_result[method_name] = time_taken
      end
    end
  end
end

class TestClass1
  include Ranno::Base
  use_annotations ClassAnnotations

  fie
  def say_hello
    puts "hello"
  end

  foo
  foo
  def say_greetings
    puts "greetings"
  end

  def self.retrieved_fied
    @fie_list
  end
  def self.retrieved_food
    @foo_list
  end
end

class TestClass2
  include Ranno::Base
  use_annotations InstanceAnnotations

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
    3 == 2 + 1
  end

  timer
  def time_me
    1.upto(1000) do
      # nothing
    end
  end

  @@fibo = {}

  timer :ignore_recursion => true
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

  timer :ignore_recursion => true
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

  def get_time_of sym
    @timer_result[sym]
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

    it "should execute multiple methods with the same class annotations" do
      TestClass2.retrieved_fied.should eql([:say_hello, :say_goodbye])
    end

    it "should allow duplicate annotations on the same method" do
      TestClass1.retrieved_food.should eql([:say_greetings, :say_greetings])
    end
  end

  describe 'Instance Annotations' do
    it "should work with a method called multiple times" do
      t2 = TestClass2.new
      
      4.times { t2.count_me_in }
      t2.get_count_of(:count_me_in).should equal(4)
    end

    it "should work with a :both hook" do
      t2 = TestClass2.new
      
      lambda {t2.time_me}.should_not raise_error
      t2.get_time_of(:time_me).should_not be_nil
      t2.get_time_of(:non_existant).should be_nil

      t2.dumb_fibonacci(15)
      t2.smart_fibonacci(15)

      # This is pretty safe ;)
      t2.get_time_of(:dumb_fibonacci).should > t2.get_time_of(:smart_fibonacci)
    end
  end

  describe User do
    it "should have a list of json-able args" do
      louis = User.new('louis', 'passw0rd', 'louis@gmail.com', '12354',
        '123 SimStreet', 'Apartment C', 'Simcity', 'WA', 'KFC')
      louis.to_json.should eql('{"username":"louis","location":["123 SimStreet"' +
        ',"Apartment C","Simcity","WA","KFC"],"zipcode":"12354","email":"louis@gmail.com"}')
    end
  end
end