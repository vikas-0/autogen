# frozen_string_literal: true

require "active_support/concern"

module RailsTypedApi
  module DSL
    extend ActiveSupport::Concern

    class_methods do
      # Usage: typed :create, params: {...}, returns: {...}, name: "CreateUser"
      def typed(action_name, params: nil, returns: nil, name: nil)
        RailsTypedApi::Registry.register(
          controller: name_for_registry,
          action: action_name.to_s,
          params_schema: RailsTypedApi::Types.normalize(params),
          response_schema: RailsTypedApi::Types.normalize(returns),
          explicit: true,
          name: name
        )
      end

      private

      def name_for_registry
        # Use the constant's name
        self.name
      end
    end
  end
end
