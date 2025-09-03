# frozen_string_literal: true

RailsTypedApi.configure do |c|
  c.types_output_path = "frontend/types"
  c.openapi_output_path = "frontend/openapi"
  c.client_variant = nil
end
