# frozen_string_literal: true

module RailsTypedApi
  class Config
    attr_accessor :types_output_path, :openapi_output_path, :client_variant

    def initialize
      @types_output_path = "frontend/types"
      @openapi_output_path = "frontend/openapi"
      @client_variant = nil
    end
  end
end
