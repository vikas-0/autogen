# frozen_string_literal: true

require "json"
require "fileutils"

namespace :typed do
  desc "Generate TypeScript types and optionally OpenAPI (flags: --openapi, --rtk or env OPENAPI=1 RTK=1)"
  task :generate => :environment do
    openapi_flag = ARGV.include?("--openapi") || ENV["OPENAPI"].to_s =~ /^(1|true)$/i
    rtk_flag = ARGV.include?("--rtk") || ENV["RTK"].to_s =~ /^(1|true)$/i
    controller_opt = ARGV.find { |a| a.start_with?("--controller=") }
    controller_filter = controller_opt&.split("=", 2)&.last || ENV["CONTROLLER"]
    controller_list = controller_filter&.split(",")&.map { |s| s.strip }&.reject(&:empty?)

    # Consume known flags from ARGV so they don't leak to other tasks
    ARGV.delete_if { |a| a == "--openapi" || a == "--rtk" || a.start_with?("--controller=") }

    # Eager load the app so that controllers/classes defining `typed` are loaded
    Rails.application.eager_load!

    endpoints = RailsTypedApi::Registry.build_endpoints

    # Optional: filter by controller(s)
    if controller_list && !controller_list.empty?
      endpoints.select! do |ep|
        ctrl_full = ep[:controller].to_s
        ctrl_base = ctrl_full.split("::").last.sub(/Controller\z/, "")
        controller_list.any? do |needle|
          n = needle.to_s
          n == ctrl_full || n == ctrl_base || n.downcase == ctrl_base.downcase || n.downcase == ctrl_full.downcase
        end
      end
    end

    out_dir = (RailsTypedApi.config&.types_output_path || RailsTypedApi::Config.new.types_output_path)
    FileUtils.mkdir_p(out_dir)
    ts_file = File.join(out_dir, "api_types.ts")
    RailsTypedApi::TypeScriptGenerator.new(endpoints, rtk: rtk_flag).write_to(ts_file)

    if openapi_flag
      openapi_dir = (RailsTypedApi.config&.openapi_output_path || RailsTypedApi::Config.new.openapi_output_path)
      FileUtils.mkdir_p(openapi_dir)
      File.write(File.join(openapi_dir, "openapi.json"), JSON.pretty_generate(RailsTypedApi::OpenAPI.build(endpoints)))
    end

    puts "RailsTypedApi: generated #{endpoints.size} endpoints"
    puts "TypeScript: #{ts_file}"
  end
end

