# frozen_string_literal: true

module RailsTypedApi
  module Types
    PRIMITIVES = {
      string: "string",
      integer: "number",
      float: "number",
      boolean: "boolean",
      uuid: "string",
      datetime: "string"
    }.freeze

    JSON_PRIMITIVES = {
      string: { type: "string" },
      integer: { type: "integer" },
      float: { type: "number" },
      boolean: { type: "boolean" },
      uuid: { type: "string", format: "uuid" },
      datetime: { type: "string", format: "date-time" }
    }.freeze

    module_function

    def normalize(schema)
      return nil if schema.nil?
      case schema
      when Symbol, String
        schema.to_sym
      when Array
        [normalize(schema.first)]
      when Hash
        schema.transform_values { |v| normalize(v) }
      else
        raise ArgumentError, "Unsupported schema node: #{schema.inspect}"
      end
    end

    def ts_type(node)
      case node
      when Symbol
        PRIMITIVES[node] || "any"
      when Array
        "#{ts_type(node.first)}[]"
      when Hash
        inner = node.map { |k, v| "#{k}: #{ts_type(v)};" }.join(" ")
        "{ #{inner} }"
      else
        "any"
      end
    end

    def json_schema(node)
      case node
      when Symbol
        JSON_PRIMITIVES[node] || { type: "string" }
      when Array
        { type: "array", items: json_schema(node.first) }
      when Hash
        {
          type: "object",
          properties: node.transform_values { |v| json_schema(v) },
          required: node.keys
        }
      else
        { type: "string" }
      end
    end

    def model_attributes_schema(klass, exclude: [])
      return nil unless klass.respond_to?(:columns_hash)
      cols = klass.columns_hash
      cols.reject { |name, _| exclude.include?(name) }.to_h do |name, col|
        [name.to_sym, primitive_from_column(col)]
      end
    end

    def primitive_from_column(col)
      case col.type
      when :integer then :integer
      when :float, :decimal then :float
      when :boolean then :boolean
      when :datetime, :timestamp, :time, :date then :datetime
      when :uuid then :uuid
      else :string
      end
    end
  end
end
