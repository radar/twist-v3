# frozen_string_literal: true

require "default_timestamps"

module Twist
  module Repos
    class CommentRepo < Twist::DB::Repo
      commands :create, use: :default_timestamps
    end
  end
end
