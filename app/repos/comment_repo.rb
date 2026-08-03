# frozen_string_literal: true

require "default_timestamps"

module Twist
  module Repos
    class CommentRepo < Twist::DB::Repo
      commands :create, use: :default_timestamps

      def by_id(id)
        comments.by_pk(id).combine(:user).one
      end

      # Everyone who has already replied on a note: they get told about the
      # replies that come after theirs.
      def participants_for(note_id)
        users
          .join(:comments, user_id: :id)
          .where(comments[:note_id] => note_id)
          .distinct
          .to_a
      end
    end
  end
end
