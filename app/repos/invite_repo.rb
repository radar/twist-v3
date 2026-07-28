# frozen_string_literal: true

require "securerandom"

module Twist
  module Repos
    class InviteRepo < Twist::DB::Repo
      commands :create, use: :default_timestamps

      def create_for(email:, invited_by:, book_ids: [])
        invite = create(
          email: email,
          token: SecureRandom.urlsafe_base64(32),
          invited_by_id: invited_by.id
        )

        unless book_ids.empty?
          invite_books
            .changeset(:create, book_ids.map { |id| {invite_id: invite.id, book_id: id} })
            .commit
        end

        invite
      end

      def find_pending_by_token(token)
        invites.where(token: token, accepted_at: nil).first
      end

      def books_for(invite)
        books
          .join(:invite_books, book_id: :id)
          .where(invite_books[:invite_id] => invite.id)
          .distinct
          .to_a
      end

      def accept!(invite)
        now = Time.now.utc
        invites.where(id: invite.id).update(accepted_at: now, updated_at: now)
      end
    end
  end
end
