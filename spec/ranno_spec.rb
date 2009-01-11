require File.dirname(__FILE__) + '/spec_helper'

module ClassAnnotations
  extend Ranno::Annotations

  attr :fie_list

  class_annotation
  def self.fie(method_name)
    @fie_list ||= []
    @fie_list << method_name
  end
end

module InstanceAnnotations
  extend Ranno::Annotations
end

class HasClassAnnotations
  include Ranno::Base

  use_annotations ClassAnnotations
end

describe "ranno" do
  describe 'Class Annotations' do
    it "should register class annotations" do
      class TestClass < HasClassAnnotations
        fie
        def say_hello
          puts "hello"
        end

        def self.retrieved_fied
          @fie_list
        end
      end
      TestClass.retrieved_fied.should equal([:say_hello])
    end
  end
end

