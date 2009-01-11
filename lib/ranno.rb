require 'rubygems'
require 'extlib'

module Ranno
  module Annotations
    class Core
      # Class annotations fire once, when the method itself is initialized

      @@class_annotations = []
      def self.class_annotation(method_name, *args, &block)
        #        puts "class annotation: #{method_name}, args are #{args.inspect}, block_given is #{block_given?}"
        @@class_annotations << method_name
      end

      @@instance_annotations = []
      # Instance annotations fire every time the method is called
      def self.instance_annotation(method_name, *args, &block)
        #        puts "new instance annotation: #{method_name}, #{args.inspect}, block_given is #{block_given?}"
        @@instance_annotations << [method_name, *args]
        #        register_class_hooks method_name.to_sym
      end

      def self.is_class_annotation? annotation
        @@class_annotations.include? annotation
      end

      def self.is_instance_annotation? annotation
        @@instance_annotations.each do |ia|
          return true if ia.first == annotation
        end
        return false
      end
    end

    def singleton_method_added(annotation)
      puts "new annotation: #{annotation}"
      if(@@core_annotations.length == 0)
        raise "Annotation needs to be labeled as class or instance"
      end
      @@core_annotations.each_pair do |ann_name, ann_data|
        #        puts "ann_name is #{ann_name}, ann_data is #{ann_data.inspect}"
        ann_data.each do |a|
          if a.key? :block
            Core.send(ann_name, annotation, *a[:args], &a[:block])
          else
            Core.send(ann_name, annotation, *a[:args])
          end
        end
      end
      @@core_annotations = {}
    end

    @@core_annotations = {}

    def method_missing(annotation, *args, &block)
      #      puts "annotation method missing: #{annotation}"
      if Core.respond_to? annotation
        ann = {:args => args}
        ann[:block] = block if block_given?
        (@@core_annotations[annotation] ||= []) << ann
      else
        super
      end
    end
  end

  module Base
    include Extlib::Hook

    @@annotations = []
    @@current_annotations = {}
    
    def use_annotations(anno_klass)
      puts "Using annotations: #{anno_klass}"
      @@annotations = @@annotations + anno_klass.methods - Object.methods
      @@anno_klass = anno_klass
    end

    def self.included(klass)
      puts "included: #{klass.inspect}"
      klass.send :include, Extlib::Hook
      klass.send :extend, Base
      klass.after_class_method(:method_added, :my_method_added)
    end

    def my_method_added(args, method)
      return if args.size > 0
      puts "Adding new method: #{method.inspect}; #{args.inspect}"
      (@@current_annotations[:class_annotation] || []).each do |ann|
        if ann.key? :block
          @@anno_klass.send(ann[:method], ann[:args], ann[:block])
        else
          ann[:args].unshift(method)
          @@anno_klass.send(ann[:method], *ann[:args])
        end

      end
      (@@current_annotations[:instance_annotation] || []).each do |ann|
        if ann.key? :block
          #          @@anno_klass.send(ann[:method], ann[:args], ann[:block])
        else
          ann[:args].unshift(method)
          #          @@anno_klass.send(ann[:method], *ann[:args])
        end
        unless method.nil?
#          puts "hooking into #{method.inspect} using #{ann[:method].inspect} now"
          puts "hook args: #{ann.inspect}"
          before(method) do
            @@anno_klass.send ann[:method], method
          end
        end
      end

      @@current_annotations = {}
    end

    register_instance_hooks :my_method_added

    def method_missing(sym, *args, &block)
      #      method_name = sym.to_s
      is_annotation = false
      if ::Ranno::Annotations::Core.is_class_annotation? sym
        puts "found a class annotation: #{sym}"
        ann = {:method => sym, :args => args}
        ann[:block] = block if block_given?
        (@@current_annotations[:class_annotation] ||= []) << ann
        is_annotation = true
      end
      if ::Ranno::Annotations::Core.is_instance_annotation? sym
        puts "found an instance annotation: #{sym}"
        ann = {:method => sym, :args => args}
        ann[:block] = block if block_given?
        (@@current_annotations[:instance_annotation] ||= []) << ann
        is_annotation = true
      end
      super unless is_annotation
    end
  end
end

module Foobar
  def method_added(method)
    puts "Adding new method: #{method}"
  end
end

#Object.send :extend, Ranno::Base