
module Twist
  module Processors
    class BookUpdater
      include Deps[
        "repos.book_repo",
        "repos.branch_repo",
        "repos.chapter_repo",
        "repos.commit_repo",
      ]

      attr_reader :permalink, :branch_name, :username, :repo
      def initialize(permalink:, branch:, username:, repo:, **args)
        super(**args)
        @permalink = permalink
        @branch_name = branch
        @username = username
        @repo = repo
      end

      def update!
        book = find_book(permalink)
        branch = find_or_create_branch(book, branch_name)

        git = Git.new(
          username: username,
          repo: repo,
          branch: branch_name,
        )


        latest_commit = git.fetch!
        commit = find_and_clean_or_create_commit(branch.id, latest_commit[:sha], latest_commit[:message])
        [git, commit]
      end

      def find_book(permalink)
        book = book_repo.find_by_permalink(permalink)
        raise "Book (#{permalink}) not found" unless book

        book
      end

      def find_or_create_branch(book, branch_name)
        branch = branch_repo.find_by_book_id_and_name(book.id, branch_name)
        unless branch
          no_default = branch_repo.no_default_for_book?(book)
          branch = branch_repo.create(book_id: book.id, name: branch_name, default: no_default)
        end
        branch
      end

      def find_branch(book, branch)
        branch = branch_repo.find_by_book_id_and_name(book.id, branch)
        branch = raise "Branch (#{branch_name}) not found" unless book
        branch
      end

      def find_and_clean_or_create_commit(branch_id, sha, message)
        commit_repo.find_and_clean_or_create(branch_id, sha, message, chapter_repo)
      end
    end
  end
end
