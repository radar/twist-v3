Hanami.app.register_provider(:sentry) do
  prepare do
    require "sentry-ruby"
  end

  start do
    Sentry.init do |config|
      config.dsn = target.settings.sentry_dsn
      config.environment = ENV.fetch("HANAMI_ENV", "development")
      config.breadcrumbs_logger = [:sentry_logger, :http_logger]

      # Performance monitoring (optional, sample rate to control cost/volume)
      config.traces_sample_rate = 0.1

      # Don't send events in dev/test by default
      config.enabled_environments = %w[production staging]
    end

    register "sentry", Sentry
  end
end
