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
        paths[path][verb] = {
          operationId: ep[:name] || default_operation_id(ep),
          requestBody: ep[:params_schema] ? {
            required: true,
            content: {
              "application/json" => {
                schema: RailsTypedApi::Types.json_schema(ep[:params_schema])
              }
            }
          } : nil,
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

    def default_operation_id(ep)
      ctrl = ep[:controller].to_s.split("::").last.sub(/Controller\z/, "")
      "#{ctrl}#{ep[:action].to_s.camelize}"
    end
  end
end
