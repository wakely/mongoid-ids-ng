module Mongoid
  module Ids
    class Options
      def initialize(options = {})
        @options = merge_defaults options
      end

      def length
        @options[:length]
      end

      def retry_count
        @options[:retry_count]
      end

      def contains
        @options[:contains]
      end

      def field_name
        @options[:field_name]
      end

      def field_name=(param)
        return if param.nil? || param.empty?
        @options[:field_name] = param
      end

      def skip_finders?
        @options[:skip_finders]
      end

      def pattern
        @options[:pattern] ||= \
        case @options[:contains].to_sym
        when :alphanumeric
          "%s#{@options[:length]}"
        when :alpha
          "%w#{@options[:length]}"
        when :alpha_upper
          "%C#{@options[:length]}"
        when :alpha_lower
          "%c#{@options[:length]}"
        when :numeric
          "%d1,#{@options[:length]}"
        when :fixed_numeric
          "%d#{@options[:length]}"
        when :fixed_numeric_no_leading_zeros
          "%D#{@options[:length]}"
        end
      end

      private

      def merge_defaults(options)
        {
          :length => 4,
          :retry_count => 3,
          :contains => :alphanumeric,
          :field_name => :_id,
          :skip_finders => false
        }.merge(options)
      end
    end
  end
end
