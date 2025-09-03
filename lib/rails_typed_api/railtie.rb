# frozen_string_literal: true

require "rails/railtie"

module RailsTypedApi
  class Railtie < ::Rails::Railtie
    initializer "rails_typed_api.controller" do
      ActiveSupport.on_load(:action_controller) do
        include RailsTypedApi::DSL
      end
    end

    config.to_prepare do
      # Clear registered entries on each reload in development to avoid stale state
      RailsTypedApi::Registry.reset! if Rails.env.development?
    end

    rake_tasks do
      load File.expand_path("../tasks/typed.rake", __dir__)
    end
  end
end
