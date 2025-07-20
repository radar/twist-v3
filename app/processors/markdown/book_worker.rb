require 'sidekiq'
require_relative 'book'
require_relative 'chapter_processor'

module Twist
  module Processors
    module Markdown
      class BookWorker
        include Sidekiq::Worker
        include Deps["repos.book_repo"]
        include Deps["repos.branch_repo"]
        include Deps["repos.commit_repo"]

        # rubocop:disable Metrics/MethodLength
        def perform(permalink)
          book = book_repo.find_by_permalink(permalink)
          book_updater = BookUpdater.new(
            permalink: permalink,
            branch: "master",
            username: book.github_user,
            repo: book.github_repo,
          )
          git, commit = book_updater.update!

          markdown_book = Markdown::Book.new(git.local_path)
          manifest = markdown_book.process_manifest
          manifest.each do |part, file_names|
            file_names.each_with_index do |file_name, position|
              ChapterProcessor.new(commit, git.local_path, file_name, part, position).process
            end
          end
        end
        # rubocop:enable Metrics/MethodLength

        private

        def find_book(permalink)
          book = book_repo.find_by_permalink(permalink)
          raise "Book (#{permalink}) not found" unless book

          book
        end

        def find_branch(book, branch)
          branch = branch_repo.find_by_book_id_and_name(book.id, branch)
          branch = raise "Branch (#{branch_name}) not found" unless book
          branch
        end

        def find_and_clean_or_create_commit(branch_id, commit)
          commit_repo.find_and_clean_or_create(branch_id, commit, Repositories::ChapterRepo.new)
        end
      end
    end
  end
end
