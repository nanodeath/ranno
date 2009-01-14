require 'rubygems'
require 'extlib'

module Ranno
  module Annotations
    # Class annotations fire once, when the method itself is initialized
    def class_annotation(method_name, definition_args={}, &block)
      # Evaluate in the scope of the including class
      self.class.class_eval do
        # Here we define the method passed into class_annotation, but we don't
        # define it using the block that was provided (because that would
        # execute immediately when the annotation was used).  Instead, we define
        # the annotation as the "queuing up" action, and include the fact that
        # it's a class annotation, as well as data about the annotation, namely
        # the name of the annotation (method_name), the arguments with which it
        # was defined (definition_args), and the args for that particular
        # invocation of the annotation (args).
        define_method(method_name) do |*args|
          add_current_annotations(:class, {
              :method => method_name,
              :definition_args => definition_args,
              :args => args})
        end
        # When method_added is triggered, it ultimately will end up executing
        # this method, conveniently named #{method_name} + "_annotation".
        # Preferably, we'd just be passing in the block in the previous method
        # definition, but this isn't possible because we want to be able to pass
        # args into the annotation.
        define_method((method_name.to_s + "_annotation").to_sym, block)
      end
    end

    # Instance annotations fire every time the method is called
    def instance_annotation(method_name, definition_args={}, &block)
      # This part is the same as the class annotation version, except :instance
      # instead of :class for the first argument to add_current_annotation.
      self.class.class_eval do
        define_method(method_name) do |*args|
          add_current_annotations(:instance, {
              :method => method_name,
              :definition_args => definition_args, 
              :args => args})
        end
      end
      # This is the same as the class annotation version, except that we're
      # evaluating it on self instead of self.class, so we have access to the
      # instance.
      self.class_eval do
        define_method((method_name.to_s + "_annotation").to_sym, block)
      end
    end
  end

  # This has to get included by every class that needs to use annotations;
  # perhaps a better name than "Base" can be found, though.
  module Base
    # necessary for before and after hooks
    include Extlib::Hook

    # A hash storing the lists of annotations for the next method that gets
    # defined.  Possible keys are :class and :instance, both of which points to
    # lists of annotations in FIFO order
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

    # Set the value for ranno_params for the next annotation execution
    def ranno_params=(ann)
      @@current_args = ann
    end

    # The annotation developer can use this to retrieve the arguments with
    # which the annotation was defined, including the hook.
    def ranno_params
      @@current_args
    end

    # The class developer uses this to include the annotations class they want
    # to use.
    def use_annotations(anno_klass)
      @@anno_klass = anno_klass
      self.send :include, anno_klass
    end

    # Updates the necessary includes and extends, as well as hooking
    # method_added and install_hook.
    def self.included(klass)
      klass.send :include, Extlib::Hook
      klass.send :extend, Base

      klass.after_class_method(:method_added, :my_method_added)
      klass.before_class_method(:install_hook, :before_install_hook)
      klass.after_class_method(:install_hook, :after_install_hook)
    end

    # The brains of the operation.  This executes every time a new method is
    # defined in the class.
    def my_method_added(args, method)
      # Hooking generates some extra methods that we can get snagged on, and
      # we don't care about them.
      return if @@hooking
      # Iterate over all the class annotations...
      (get_current_annotations[:class] || []).each do |ann|
        # Set the ranno_params helper to the definition args of the annotation.
        self.ranno_params = ann[:definition_args]
        # And fire off the annotation.
        self.send((ann[:method].to_s + '_annotation').to_sym, method, *ann[:args])
      end
      (get_current_annotations[:instance] || []).each do |ann|
        # Not going to make any assumptions about hooking
        hook_before = hook_after = false
        ann[:definition_args].each_pair do |key, value|
          if key == :hook
            # Handles the [:before], [:after], [:before, :after] cases
            if value.is_a? Array
              hook_before = true if value.include? :before
              hook_after = true if value.include? :after
            else
              # Handles the :before, :after, :both cases
              hook_before = true if value == :before
              hook_after = true if value == :after
              hook_before = hook_after = true if value == :both
            end
          end
        end

        # Set up the before hook
        if hook_before
          before(method) do
            # Get a copy of the definition args and update the hook to :before
            # (overwrites :both, if it was there)
            tmp_params = ann[:definition_args]
            tmp_params[:hook] = :before
            self.ranno_params = tmp_params
            annotation_method = (ann[:method].to_s + '_annotation').to_sym
            self.send annotation_method, method, *ann[:args]
          end
        end

        if hook_after
          after(method) do
            # Same as above...
            tmp_params = ann[:definition_args]
            tmp_params[:hook] = :after
            self.ranno_params = tmp_params
            annotation_method = (ann[:method].to_s + '_annotation').to_sym
            self.send annotation_method, method, *ann[:args]
          end
        end
      end

      # Done with these annotations; clear them so they don't execute again
      reset_annotations_for_next_method
    end

    register_instance_hooks :my_method_added

    # Just some stuff so we can keep tracking of whether we're hooking or not
    # Executes around Extlib's hooking stuff, not mine
    @@hooking = false
    def before_install_hook
      @@hooking = true
    end

    def after_install_hook
      @@hooking = false
    end
  end
end