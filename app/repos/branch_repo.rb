# frozen_string_literal: true

module Twist
  module Repos
    class BranchRepo < Twist::DB::Repo
      commands :create, use: :timestamps, plugins_options: { timestamps: { timestamps: %i(created_at updated_at) } }
    end
  end
end
