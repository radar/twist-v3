# frozen_string_literal: true

module Twist
  module Repos
    class CommitRepo < Twist::DB::Repo
      commands :create, use: :default_timestamps

      def by_id(id)
        commits.by_pk(id).one
      end

      def by_id_with_branch(id)
        commits.by_pk(id).combine(:branch).one!
      end

      def latest_for_branch(branch_id)
        by_branch(branch_id)
          .order { created_at.desc }
          .limit(1)
          .one!
      end

      def latest_by_book_permalink(book_permalink:)
        commits.latest_by_book_permalink(book_permalink:)
      end

      def find_and_clean_or_create(branch_id, sha, message, chapter_repo)
        fields = { branch_id: branch_id, sha: sha, message: message }

        commit = commits.where(fields).limit(1).one
        if commit
          chapter_repo.mark_as_superseded(commit)
          commit
        else
          create(fields)
        end
      end

      private

      def by_branch(branch_id)
        commits.where(branch_id: branch_id)
      end
    end
  end
end
