# frozen_string_literal: true

require 'default_timestamps'
require 'securerandom'

module Twist
  module Repos
    class BookRepo < Twist::DB::Repo
      commands :create, use: :default_timestamps

      def all
        books.to_a
      end

      def by_id(id)
        books.by_pk(id).one
      end

      def find_by_permalink(permalink)
        require_permalink!(permalink)
        books.where(permalink: permalink).one!
      end

      # Like #find_by_permalink, but returns nil instead of raising when no
      # book matches the permalink.
      def by_permalink(permalink)
        return nil if permalink.nil? || permalink.empty?

        books.where(permalink: permalink).one
      end

      def find_by_permalink_with_latest_commit(permalink)
        require_permalink!(permalink)
        books.combine(default_branch: :latest_commit).where(permalink: permalink).one!
      end

      def add_branch(book, data)
        branches
          .changeset(:create, data.merge(book_id: book.id))
          .map(:add_timestamps)
          .commit
      end

      # The shared secret GitHub signs this book's webhook deliveries with, or
      # nil when the book has never had one set.
      def webhook_secret_for(book)
        books.where(id: book.id).one!.webhook_secret
      end

      # Generates a fresh webhook secret for the book and returns it. Any
      # deliveries signed with the previous secret stop being accepted.
      def rotate_webhook_secret(book)
        secret = SecureRandom.hex(20)
        set_webhook_secret(book: book, secret: secret)
        secret
      end

      def set_webhook_secret(book:, secret:)
        books
          .where(id: book.id)
          .update(webhook_secret: secret, updated_at: Time.now.utc)

        secret
      end

      def permitted?(book:, user:)
        permissions.where(book_id: book.id, user_id: user.id).exist?
      end

      def author?(book:, user:)
        return false if user.nil?

        permissions.where(book_id: book.id, user_id: user.id, author: true).exist?
      end

      def permitted_for_user(user)
        books
          .join(:permissions, book_id: :id)
          .where(permissions[:user_id] => user.id)
          .distinct
          .to_a
      end

      def authored_by(user)
        books
          .join(:permissions, book_id: :id)
          .where(permissions[:user_id] => user.id, permissions[:author] => true)
          .distinct
          .to_a
      end

      # Everyone with access to the book, each struct carrying the `author` flag
      # from their permission row.
      def people_for(book)
        users
          .join(:permissions, user_id: :id)
          .where(permissions[:book_id] => book.id)
          .select_append(permissions[:author])
          .order(:name)
          .to_a
      end

      # Everyone who can act on a note: the people notifications go to.
      def authors_for(book)
        users
          .join(:permissions, user_id: :id)
          .where(permissions[:book_id] => book.id, permissions[:author] => true)
          .order(:name)
          .to_a
      end

      def author_count(book)
        permissions.where(book_id: book.id, author: true).count
      end

      def set_author(book:, user:, author:)
        permissions.where(book_id: book.id, user_id: user.id).update(author: author)
      end

      def grant_permission(book:, user:, author: false)
        permissions
          .changeset(:create, { book_id: book.id, user_id: user.id, author: author })
          .commit
      end

      private

      # `permalink` is nullable, so a nil lookup would quietly match whichever
      # book happens to have no permalink rather than finding nothing.
      def require_permalink!(permalink)
        return unless permalink.nil? || permalink.empty?

        raise ArgumentError, "permalink must be present"
      end
    end
  end
end
