require 'mongoid/ids/exceptions'
require 'mongoid/ids/options'
require 'mongoid/ids/generator'
require 'mongoid/ids/finders'
require 'mongoid/ids/collision_resolver'

module Mongoid
  module Ids
    extend ActiveSupport::Concern

    module ClassMethods
      # def initialize_copy(source)
      #   super(source)
      #   self.token = nil
      # end

      def token(*args)
        options = Mongoid::Ids::Options.new(args.extract_options!)
        options.field_name = args.join

        add_token_collision_resolver(options)

        if options.field_name == :_id
          self.field :_id, default: -> { generate_token(options.pattern) }
        else
          set_token_callbacks(options)
          add_token_field_and_index(options)

          define_custom_finders(options) if options.skip_finders? == false
        end
      end

      private
      def add_token_field_and_index(options)
        self.field(options.field_name, :type => String, :default => nil)
        self.index({ options.field_name => 1 }, { :unique => true, :sparse => true })
      end

      def add_token_collision_resolver(options)
        resolver = Mongoid::Ids::CollisionResolver.new(self, options.field_name, options.retry_count)
        resolver.create_new_token = Proc.new do |document|
          document.send(:create_token, options.field_name, options.pattern)
        end
      end

      def define_custom_finders(options)
        Finders.define_custom_token_finder_for(self, options.field_name)
      end

      def set_token_callbacks(options)
        set_callback(:create, :before) do |document|
          document.create_token_if_nil options.field_name, options.pattern
        end

        set_callback(:save, :before) do |document|
          document.create_token_if_nil options.field_name, options.pattern
        end
      end
    end

    protected
    def create_token(field_name, pattern)
      self.send :"#{field_name.to_s}=", self.generate_token(pattern)
    end

    def create_token_if_nil(field_name, pattern)
      if self[field_name.to_sym].blank?
        self.create_token field_name, pattern
      end
    end

    def generate_token(pattern)
      Mongoid::Ids::Generator.generate pattern
    end
  end
end
