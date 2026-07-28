# frozen_string_literal: true

require "hanami/rake_tasks"


namespace :import do
  task :asciidoc, [:permalink, :branch] => :environment do |t, args|

    payload = {
      "permalink" => args[:permalink],
      "branch" => args[:branch] || "main",
    }

    Twist::Processors::Asciidoc::BookWorker.new.perform(payload)
  end
end
