module RSpec
  module Core
    class World

      attr_reader :example_groups, :filtered_examples

      def initialize(configuration=RSpec.configuration)
        @configuration = configuration
        @example_groups = []
        @filtered_examples = Hash.new { |hash,group|
          hash[group] = begin
            examples = group.examples.dup
            examples = apply_exclusion_filters(examples, exclusion_filter) if exclusion_filter
            examples = apply_inclusion_filters(examples, inclusion_filter) if inclusion_filter
            examples.uniq
          end
        }
      end

      def inclusion_filter
        @configuration.filter
      end

      def exclusion_filter
        @configuration.exclusion_filter
      end

      def find_modules(group)
        @configuration.find_modules(group)
      end

      def shared_example_groups
        @shared_example_groups ||= {}
      end

      def example_count
        example_groups.collect {|g| g.descendants}.flatten.inject(0) { |sum, g| sum += g.filtered_examples.size }
      end

      def apply_inclusion_filters(examples, conditions={})
        examples.select &all_apply?(conditions)
      end

      alias_method :find, :apply_inclusion_filters

      def apply_exclusion_filters(examples, conditions={})
        examples.reject &all_apply?(conditions)
      end

      def preceding_declaration_line(filter_line) 
        declaration_line_numbers.inject(nil) do |highest_prior_declaration_line, line|
          line <= filter_line ? line : highest_prior_declaration_line
        end
      end

      def announce_inclusion_filter
        if inclusion_filter
          if @configuration.run_all_when_everything_filtered? && RSpec.world.example_count == 0
            @configuration.reporter.message "No examples were matched by #{inclusion_filter.inspect}, running all"
            @configuration.clear_inclusion_filter
            filtered_examples.clear
          else
            @configuration.reporter.message "Run filtered using #{inclusion_filter.inspect}"
          end
        end      
      end

      include RSpec::Core::Hooks

      def find_hook(hook, scope, group)
        @configuration.find_hook(hook, scope, group)
      end

    private

      def all_apply?(conditions)
        lambda {|example| example.metadata.all_apply?(conditions)}
      end

      def declaration_line_numbers
        @line_numbers ||= example_groups.inject([]) do |lines, g|
          lines + g.declaration_line_numbers
        end
      end
      
    end
  end
end
