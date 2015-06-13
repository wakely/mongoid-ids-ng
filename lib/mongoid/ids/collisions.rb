module Mongoid
  module Ids
    # Resolve token/id collisions
    module Collisions
      def resolve_token_collisions(resolver)
        retries = resolver.retry_count
        begin
          yield
        rescue Mongo::Error::OperationFailure => e
          if duplicate_token_error?(e, self, resolver.field_name)
            if (retries -= 1) >= 0
              resolver.create_new_token_for(self)
              retry
            end
            raise_collision_retries_exceeded_error resolver.field_name, resolver.retry_count
          else
            raise e
          end
        end
      end

      def raise_collision_retries_exceeded_error(field_name, retry_count)
        Rails.logger.warn "[Mongoid::Ids] Warning: Maximum token generation retries (#{retry_count}) exceeded on `#{field_name}'." if defined?(Rails)
        raise Mongoid::Ids::CollisionRetriesExceeded.new(self, retry_count)
      end

      def duplicate_token_error?(err, document, field_name)
        err.message =~ /E1100[01] duplicate key/ &&
          err.message =~ /"#{document.send(field_name)}"/
      end
    end
  end
end
