require 'rubygems'
require 'extlib'

module Ranno
  module Annotations
    # Class annotations fire once, when the method itself is initialized
    def class_annotation(method_name, definition_args={}, &block)
      self.class.class_eval do
        define_method(method_name) do |*args|
          add_current_annotations(:class, {
              :method => method_name,
              :definition_args => definition_args,
              :args => args})
        end
        define_method((method_name.to_s + "_annotation").to_sym, block)
      end
    end

    # Instance annotations fire every time the method is called
    def instance_annotation(method_name, definition_args={}, &block)
      self.class.class_eval do
        define_method(method_name) do |*args|
          add_current_annotations(:instance, {
              :method => method_name,
              :definition_args => definition_args, 
              :args => args})
        end
      end
      self.class_eval do
        define_method((method_name.to_s + "_annotation").to_sym, block)
      end
    end
  end

  module Base
    include Extlib::Hook

    @@annotations_for_next_method = {}
    def get_current_annotations
      @@annotations_for_next_method
    end

    def add_current_annotations(type, value)
      (@@annotations_for_next_method[type] ||= []).push(value)
    end

    def reset_annotations_for_next_method
      @@annotations_for_next_method = {}
    end

    def ranno_params=(ann)
      @@current_args = ann
    end

    def ranno_params
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
        self.ranno_params = ann[:definition_args]
        self.send((ann[:method].to_s + '_annotation').to_sym, method, *ann[:args])
      end
      (get_current_annotations[:instance] || []).each do |ann|
        #        puts "ann is #{ann[:args].inspect}"
        hook_before = hook_after = false
        ann[:definition_args].each_pair do |key, value|
          if key == :hook
            if value.is_a? Array
              hook_before = true if value.include? :before
              hook_after = true if value.include? :after
            else
              hook_before = true if value == :before
              hook_after = true if value == :after
              hook_before = hook_after = true if value == :both
            end
          end
        end

        if hook_before
          before(method) do
            tmp_params = ann[:definition_args]
            tmp_params[:hook] = :before
            self.ranno_params = tmp_params
            annotation_method = (ann[:method].to_s + '_annotation').to_sym
            self.send annotation_method, method, *ann[:args]
          end
        end

        if hook_after
          after(method) do
            tmp_params = ann[:definition_args]
            tmp_params[:hook] = :after
            self.ranno_params = tmp_params
            annotation_method = (ann[:method].to_s + '_annotation').to_sym
            self.send annotation_method, method, *ann[:args]
          end
        end
      end

      reset_annotations_for_next_method
    end

    register_instance_hooks :my_method_added

    @@hooking = false
    def before_install_hook
      @@hooking = true
    end

    def after_install_hook
      @@hooking = false
    end
  end
end