# frozen_string_literal: true

require "active_support/core_ext/hash/indifferent_access"
require "active_support/inflector"

module RailsTypedApi
  class Registry
    Entry = Struct.new(
      :controller, :action, :params_schema, :response_schema, :explicit, :name,
      keyword_init: true
    )

    @entries = []
    class << self
      def register(controller:, action:, params_schema:, response_schema:, explicit: false, name: nil)
        remove(controller: controller, action: action)
        @entries << Entry.new(controller: controller, action: action, params_schema: params_schema, response_schema: response_schema, explicit: explicit, name: name)
      end

      def remove(controller:, action:)
        @entries.reject! { |e| e.controller == controller && e.action == action }
      end

      def entries
        @entries.dup
      end

      # Build endpoints by integrating routes and filling in inference for missing ones
      def build_endpoints
        routes = collect_routes
        endpoints = []

        routes.each do |rt|
          controller = rt[:controller]
          action = rt[:action]
          entry = @entries.find { |e| e.controller == controller && e.action == action }

          unless entry
            # Prefer Sorbet-based inference if available, then fallback to heuristic
            sorbet_entry = RailsTypedApi.const_defined?(:Sorbet) ? RailsTypedApi::Sorbet.infer_entry(controller, action) : nil
            heur_entry = nil
            if sorbet_entry
              heur_entry = infer_entry(controller, action)
              if sorbet_entry.params_schema.nil? && heur_entry&.params_schema
                sorbet_entry.params_schema = heur_entry.params_schema
              end
              if sorbet_entry.response_schema.nil? && heur_entry&.response_schema
                sorbet_entry.response_schema = heur_entry.response_schema
              end
              entry = sorbet_entry
            else
              entry = infer_entry(controller, action)
            end
          end

          next unless entry

          endpoints << entry_to_endpoint(entry, rt)
        end

        endpoints
      end

      private

      def collect_routes
        return [] unless defined?(Rails) && Rails.respond_to?(:application)
        Rails.application.routes.routes.map do |r|
          reqs = r.defaults
          controller = reqs[:controller]
          action = reqs[:action]
          next nil if controller.nil? || action.nil?
          {
            controller: controller.to_s.camelize.concat("Controller"),
            action: action.to_s,
            verb: verb_for_route(r),
            path: path_for_route(r)
          }
        end.compact.uniq
      end

      def verb_for_route(route)
        if route.verb.respond_to?(:source)
          route.verb.source.gsub("^", "").gsub("$", "")
        else
          route.verb.to_s
        end
      rescue
        "GET"
      end

      def path_for_route(route)
        if route.path.respond_to?(:spec)
          route.path.spec.to_s
        else
          route.path.to_s
        end
      rescue
        "/"
      end

      def infer_entry(controller_name, action)
        # Heuristic: map Controller to model and infer schemas
        model_klass = model_for_controller(controller_name)
        return nil unless model_klass

        params_schema = nil
        response_schema = nil

        case action.to_s
        when "create", "update"
          params_schema = Types.model_attributes_schema(model_klass, exclude: %w[id created_at updated_at])
          response_schema = Types.model_attributes_schema(model_klass)
        when "show"
          response_schema = Types.model_attributes_schema(model_klass)
        when "index"
          response_schema = [Types.model_attributes_schema(model_klass)]
        when "destroy"
          response_schema = { success: :boolean }
        else
          # no inference
        end

        return nil unless params_schema || response_schema

        Entry.new(controller: controller_name, action: action.to_s, params_schema: params_schema, response_schema: response_schema, explicit: false, name: nil)
      rescue NameError
        nil
      end

      def model_for_controller(controller_name)
        base = controller_name.to_s.sub(/Controller\z/, "")
        # Prefer last segment singularized
        class_name = base.split("::").last.singularize
        Object.const_get(class_name)
      rescue NameError
        nil
      end

      def entry_to_endpoint(entry, route)
        {
          controller: entry.controller,
          action: entry.action,
          name: entry.name || default_operation_name(entry.controller, entry.action),
          verb: route[:verb],
          path: normalize_path(route[:path]),
          params_schema: entry.params_schema,
          response_schema: entry.response_schema,
          explicit: entry.explicit
        }
      end

      def default_operation_name(controller, action)
        ctrl = controller.to_s.split("::").last.sub(/Controller\z/, "")
        "#{ctrl}#{action.camelize}"
      end

      def normalize_path(path)
        p = path.to_s
        p.sub(/\(\.\:format\)\z/, "")
      end
    end
  end
end
