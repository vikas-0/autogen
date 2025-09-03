# frozen_string_literal: true

module RailsTypedApi
  module Sorbet
    module_function

    def infer_entry(controller_name, action)
      return nil unless sorbet_available?

      base = controller_name.to_s.split("::").last.sub(/Controller\z/, "")
      op = action.to_s.camelize
      req_klass = constantize_safely("#{base}#{op}Request")
      res_klass = constantize_safely("#{base}#{op}Response")

      return nil unless req_klass || res_klass

      params_schema = req_klass ? struct_schema(req_klass) : nil
      response_schema = res_klass ? struct_schema(res_klass) : nil

      return nil unless params_schema || response_schema

      RailsTypedApi::Registry::Entry.new(
        controller: controller_name,
        action: action.to_s,
        params_schema: params_schema,
        response_schema: response_schema,
        explicit: false,
        name: nil
      )
    rescue => _e
      nil
    end

    def sorbet_available?
      defined?(::T) && defined?(::T::Struct)
    end

    def struct_schema(klass)
      return nil unless klass <= ::T::Struct
      dec = klass.respond_to?(:decorator) ? klass.decorator : nil
      props = dec && dec.respond_to?(:props) ? dec.props : {}
      props.each_with_object({}) do |(name, prop), h|
        t = prop_type(prop)
        h[name.to_sym] = map_type(t)
      end
    end

    # Extract the type object from a T::Struct prop record
    def prop_type(prop)
      prop.respond_to?(:type) ? prop.type : nil
    end

    def map_type(t)
      return :string if t.nil?

      # Nilable: unwrap
      if t.class.name.include?("Nilable") && t.respond_to?(:type)
        return map_type(t.type)
      end

      # Union: pick first non-nil
      if t.class.name.include?("Union") && t.respond_to?(:types)
        first = t.types.find { |x| !raw_type_nil?(x) } || t.types.first
        return map_type(first)
      end

      # Array type
      if t.class.name.include?("TypedArray") && t.respond_to?(:type)
        return [map_type(t.type)]
      end

      raw = t.respond_to?(:raw_type) ? t.raw_type : nil

      # Nested T::Struct
      if raw && raw <= ::T::Struct
        return struct_schema(raw)
      end

      case raw
      when String then :string
      when Integer then :integer
      when Float, BigDecimal then :float
      when TrueClass, FalseClass then :boolean
      when Time, DateTime, Date then :datetime
      else
        :string
      end
    end

    def raw_type_nil?(t)
      rt = t.respond_to?(:raw_type) ? t.raw_type : nil
      rt == NilClass
    end

    def constantize_safely(name)
      Object.const_get(name)
    rescue NameError
      nil
    end
  end
end
