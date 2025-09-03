# frozen_string_literal: true

require "rails_typed_api/version"
require "rails_typed_api/config"
require "rails_typed_api/types"
require "rails_typed_api/utils"
require "rails_typed_api/registry"
require "rails_typed_api/dsl"
require "rails_typed_api/ts_generator"
require "rails_typed_api/openapi"
require "rails_typed_api/sorbet"
require "rails_typed_api/railtie" if defined?(Rails)

module RailsTypedApi
  class << self
    attr_accessor :config
  end

  def self.configure
    self.config ||= Config.new
    yield config
  end
end
