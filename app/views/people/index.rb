# frozen_string_literal: true

module Twist
  module Views
    module People
      class Index < Twist::View
        include Deps["repos.book_repo"]
        include Deps["repos.invite_repo"]
        include Deps["repos.user_repo"]

        expose :book
        expose :current_user

        expose :people do |book|
          book_repo.people_for(book)
        end

        expose :author_count do |book|
          book_repo.author_count(book)
        end

        expose :pending_invites do |book|
          invite_repo.pending_for_book(book)
        end

        # user_id => user, for naming whoever sent each pending invite.
        expose :inviters do |pending_invites|
          user_repo
            .find_all(pending_invites.map(&:invited_by_id).uniq)
            .to_h { |user| [user.id, user] }
        end
      end
    end
  end
end
