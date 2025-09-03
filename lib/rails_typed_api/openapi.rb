# frozen_string_literal: true

require "json"

module RailsTypedApi
  module OpenAPI
    module_function

    def build(endpoints)
      {
        openapi: "3.0.3",
        info: { title: "Rails Typed API", version: "#{RailsTypedApi::VERSION}" },
        paths: build_paths(endpoints)
      }
    end

    def build_paths(endpoints)
      paths = {}
      endpoints.each do |ep|
        path = ep[:path]
        verb = (ep[:verb].to_s.split("|").first || "get").downcase
        paths[path] ||= {}
        params = build_path_parameters(ep)
        # Place parameters at path-level for broader tooling compatibility
        if params.any?
          (paths[path][:parameters] ||= [])
          # Avoid duplicates when multiple verbs share the same path
          params.each do |p|
            unless paths[path][:parameters].any? { |existing| existing[:in] == p[:in] && existing[:name] == p[:name] }
              paths[path][:parameters] << p
            end
          end
        end
        paths[path][verb] = {
          operationId: ep[:name] || RailsTypedApi::NameUtils.operation_name(ep[:controller], ep[:action]),
          requestBody: request_body_for(verb, ep[:params_schema]),
          responses: {
            "200" => {
              description: "OK",
              content: {
                "application/json" => {
                  schema: RailsTypedApi::Types.json_schema(ep[:response_schema])
                }
              }
            }
          }
        }.compact
      end
      paths
    end

    def build_path_parameters(ep)
      path = ep[:path]
      names = path.to_s.scan(/\{([A-Za-z_][A-Za-z0-9_]*)\}/).flatten
      names.map do |n|
        schema = path_param_schema_for(ep, n)
        { name: n, in: "path", required: true, schema: schema }
      end
    end

    def path_param_schema_for(ep, name)
      # Default
      schema = { type: "string" }
      # Prefer DSL params schema if provided for this name
      if ep[:params_schema].is_a?(Hash)
        key = name.to_sym
        if ep[:params_schema].key?(key)
          return RailsTypedApi::Types.json_schema(ep[:params_schema][key])
        end
      end
      schema
    end

    def request_body_for(verb, params_schema)
      return nil unless params_schema
      return nil if %w[get delete].include?(verb)
      {
        required: true,
        content: {
          "application/json" => {
            schema: RailsTypedApi::Types.json_schema(params_schema)
          }
        }
      }
    end
  end
end
