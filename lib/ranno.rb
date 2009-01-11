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
        @@instance_annotations << {:method => method_name, :args => args, :block => block}
      end

      def self.is_class_annotation? annotation
        @@class_annotations.include? annotation
      end

      def self.is_instance_annotation? annotation
        @@instance_annotations.each do |ia|
          return true if ia[:method] == annotation
        end
        return false
      end

      def self.get_instance_annotation annotation
        @@instance_annotations.each do |ia|
          return ia if ia[:method] == annotation
        end
        return nil
      end
    end

    def set_current_instance_annotation=(ann)
      @@instance_annotation = ann
    end

    def annotation_args
      @@instance_annotation
    end

    def singleton_method_added(annotation)
      #      puts "new annotation: #{annotation}"
      if(@@core_annotations.length == 0)
        #        raise "Annotation needs to be labeled as class or instance"
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
      #      puts "Using annotations: #{anno_klass}"
      @@annotations = @@annotations + anno_klass.methods - Object.methods
      @@anno_klass = anno_klass
      self.send :include, anno_klass
    end

    def self.included(klass)
      klass.send :include, Extlib::Hook
      klass.send :extend, Base

      klass.after_class_method(:method_added, :my_method_added)
      klass.before_class_method(:install_hook, :before_install_hook)
      klass.after_class_method(:install_hook, :after_install_hook)
    end

    @@hooking = false
    def before_install_hook
      @@hooking = true
    end

    def after_install_hook
      @@hooking = false
    end

    def my_method_added(args, method)
      #      (puts "returing: #{method}; #{args.inspect}" or return) if args.key? method or @@hooking
      return if @@hooking
      #      return "method not defined" unless method_defined?(method)
      #      puts "Adding new method: #{method.inspect}; #{args.inspect}"
      #      puts "was #{method.inspect} already a key in #{args.inspect}? #{args.key? method}"
      (@@current_annotations[:class_annotation] || []).each do |ann|
        if ann.key? :block
          @@anno_klass.send(ann[:method], ann[:args], ann[:block])
        else
          ann[:args].unshift(method)
          #          puts ann[:args].inspect
          @@anno_klass.send(ann[:method], *ann[:args])
        end

      end
      (@@current_annotations[:instance_annotation] || []).each do |ann|
        if ann.key? :block
          #          @@anno_klass.send(ann[:method], ann[:args], ann[:block])
        else
          #          ann[:args].unshift(method)
          #          @@anno_klass.send(ann[:method], *ann[:args])
        end
        unless method.nil?
          #          puts "hook args: #{ann.inspect}"
          #          next if ann[:args].length > 1
          annotation_args = ::Ranno::Annotations::Core.get_instance_annotation(ann[:method])
          #          puts "instance annotation args are #{annotation_args.inspect}"
          if annotation_args[:args].include?(:before) || !annotation_args[:args].include?(:after)
            before(method) do
              @@anno_klass.set_current_instance_annotation = annotation_args[:args].reject {|k,v| k == :after}
              @@anno_klass.send ann[:method], method, *ann[:args]
            end
          end
          if annotation_args[:args].include? :after
            after(method) do
              @@anno_klass.set_current_instance_annotation = annotation_args[:args].reject {|k,v| k == :before}
              @@anno_klass.send ann[:method], method, *ann[:args]
            end
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
        #        puts "found a class annotation: #{sym}"
        ann = {:method => sym, :args => args}
        ann[:block] = block if block_given?
        (@@current_annotations[:class_annotation] ||= []) << ann
        is_annotation = true
      end
      if ::Ranno::Annotations::Core.is_instance_annotation? sym
        #        puts "found an instance annotation: #{sym}"
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