# frozen_string_literal: true

module RailsTypedApi
  module Utils
    module_function

    def normalize_path(path)
      p = path.to_s
      p = p.sub(/\(\.\:format\)\z/, "")
      p.gsub(/:([A-Za-z_][A-Za-z0-9_]*)/, '{\1}')
    end

    def extract_path_params(path)
      path.to_s.scan(/\{([A-Za-z_][A-Za-z0-9_]*)\}/).flatten.map(&:to_s)
    end

    def log_debug(message, error = nil)
      full = error ? "[rails_typed_api] #{message}: #{error.class} #{error.message}" : "[rails_typed_api] #{message}"
      if defined?(Rails) && Rails.respond_to?(:logger) && Rails.logger
        Rails.logger.debug(full)
      else
        warn(full)
      end
    end
  end
end
