require 'rubygems'
require 'extlib'

module Ranno
  module Annotations
    # Class annotations fire once, when the method itself is initialized
    def class_annotation(method_name, *args, &block)
      self.class.send(:define_method, method_name) do |*args|
        add_current_annotations(:class, {:method => method_name, :args => args})
      end
      self.class.send(:define_method, (method_name.to_s + "_annotation").to_sym, &block)
#      class << self
#        define_method((method_name.to_s + "_annotation").to_sym, block)
#      end
    end

    # Instance annotations fire every time the method is called
    def instance_annotation(method_name, *args, &block)
      self.class.send(:define_method, method_name) do |*args2|
        add_current_annotations(:instance, {:method => method_name, :args => args, :block => block})
      end
      self.send(:define_method, (method_name.to_s + "_annotation").to_sym, &block)
    end
  end

  module Base
    include Extlib::Hook

    @@current_annotations = {}
    def get_current_annotations
      @@current_annotations
    end

    def add_current_annotations(type, value)
      (@@current_annotations[type] ||= []).push(value)
    end

    def params=(ann)
      @@current_args = ann
    end

    def params
      @@current_args
    end
    
    def use_annotations(anno_klass)
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

    def my_method_added(args, method)
      return if @@hooking
      (get_current_annotations[:class] || []).each do |ann|
        self.send((ann[:method].to_s + '_annotation').to_sym, method, *ann[:args])
      end
      (get_current_annotations[:instance] || []).each do |ann|
        hook_before = hook_after = false
        ann[:args].each do |arg|
          if arg.is_a? Hash
            if arg[:hook].is_a? Array
              hook_before = true if arg[:hook].include? :before
              hook_after = true if arg[:hook].include? :after
            else
              hook_before = true if arg[:hook] == :before
              hook_after = true if arg[:hook] == :after
            end
          end
        end
        if hook_before
          before(method) do
            self.params = {:method => method, :args => ann[:args].reject {|key| key == :after}}
            annotation_method = (ann[:method].to_s + '_annotation').to_sym
            self.send annotation_method, method, *ann[:args]
          end
        end
        if hook_after
          after(method) do
            self.params = {:method => method, :args => ann[:args].reject {|key| key == :after}}
            annotation_method = (ann[:method].to_s + '_annotation').to_sym
            self.send annotation_method, method, *ann[:args]
          end
        end
      end

      @@current_annotations = {}
    end

    register_instance_hooks :my_method_added

    #    def method_missing(sym, *args, &block)
    #      #      method_name = sym.to_s
    #      is_annotation = false
    #      if ::Ranno::Annotations.is_class_annotation? sym
    #        #        puts "found a class annotation: #{sym}"
    #        ann = {:method => sym, :args => args}
    #        ann[:block] = block if block_given?
    #        (@@current_annotations[:class_annotation] ||= []) << ann
    #        is_annotation = true
    #      end
    #      if ::Ranno::Annotations::Core.is_instance_annotation? sym
    #        #        puts "found an instance annotation: #{sym}"
    #        ann = {:method => sym, :args => args}
    #        ann[:block] = block if block_given?
    #        (@@current_annotations[:instance_annotation] ||= []) << ann
    #        is_annotation = true
    #      end
    #      super unless is_annotation
    #    end


    @@hooking = false
    def before_install_hook
      @@hooking = true
    end

    def after_install_hook
      @@hooking = false
    end
  end
end