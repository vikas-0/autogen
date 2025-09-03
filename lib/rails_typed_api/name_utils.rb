# frozen_string_literal: true

module RailsTypedApi
  module NameUtils
    module_function

    # Returns the un-namespaced controller base (e.g., Api::UsersController -> Users)
    def controller_base(controller)
      controller.to_s.split("::").last.sub(/Controller\z/, "")
    end

    # Default operation name used across generators (e.g., UsersShow)
    def operation_name(controller, action)
      "#{controller_base(controller)}#{action.to_s.camelize}"
    end

    # Interface base name for TS types
    # Prefers explicit ep[:name], else operation_name
    def interface_base_name(ep)
      (ep[:name] || operation_name(ep[:controller], ep[:action])).gsub(/[^A-Za-z0-9]/, "")
    end

    # Endpoint key for RTK builder and hooks (camelCase)
    def endpoint_key(ep)
      base = ep[:name] || (controller_base(ep[:controller]) + "_" + ep[:action].to_s)
      base = base.gsub(/[^A-Za-z0-9]+/, '_').underscore
      base.camelize(:lower)
    end
  end
end
