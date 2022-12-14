require 'mongoid/ids/collisions'

module Mongoid
  module Ids
    module SafeOperationsHandler
      def insert(options = {})
        safe_operation { super(options) }
      end

      def upsert(options = {})
        safe_operation { super(options) }
      end

      def safe_operation(&block)
        resolve_token_collisions { with(write: { w: 1 }, &block) }
      end
    end
    class CollisionResolver
      attr_accessor :create_new_token
      attr_reader :klass
      attr_reader :field_name
      attr_reader :retry_count

      def initialize(klass, field_name, retry_count)
        @create_new_token = Proc.new {|doc|}
        @klass = klass
        @field_name = field_name
        @retry_count = retry_count
        klass.send(:include, Mongoid::Ids::Collisions)
        klass.send(:prepend, SafeOperationsHandler)
        # alias_method_with_collision_resolution(:insert)
        # alias_method_with_collision_resolution(:upsert)
      end

      def create_new_token_for(document)
        @create_new_token.call(document)
      end

      # private
      # def alias_method_with_collision_resolution(method)
      #   handler = self
      #   klass.send(:define_method, :"#{method.to_s}_with_#{handler.field_name}_safety") do |method_options = {}|
      #     self.resolve_token_collisions handler do
      #       with(:safe => true).send(:"#{method.to_s}_without_#{handler.field_name}_safety", method_options)
      #     end
      #   end
      #   klass.alias_method_chain method.to_sym, :"#{handler.field_name}_safety"
      # end
    end
  end
end
