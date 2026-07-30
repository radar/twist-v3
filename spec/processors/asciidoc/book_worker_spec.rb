require "spec_helper"

module Twist
  module Processors
    module Asciidoc
      RSpec.describe BookWorker do
        let(:book_repo) { Twist::Repos::BookRepo.new }
        let(:branch_repo) { Twist::Repos::BranchRepo.new }
        let(:chapter_repo) { Twist::Repos::ChapterRepo.new }
        let(:commit_repo) { Twist::Repos::CommitRepo.new }
        let(:footnote_repo) { Twist::Repos::FootnoteRepo.new }

        context "with test book" do
          let!(:book) do
            book_repo.create(
              permalink: "asciidoc-book-test",
              title: "Asciidoc Book Test",
              github_user: "radar",
              github_repo: "asciidoc_book_test",
            )
          end

          let!(:branch) { book_repo.add_branch(book, name: "master") }

          it "can process the book" do
            subject.perform(
              "permalink" => book.permalink,
              "branch" => branch.name,
            )

            commit = commit_repo.latest_for_branch(branch.id)
            expect(commit.message).not_to be_nil
            frontmatter_titles = chapter_repo.for_commit_and_part(commit, "frontmatter").map(&:title)

            expect(frontmatter_titles).to eq(["Preface / Introduction"])

            mainmatter_chapters = chapter_repo.for_commit_and_part(commit, "mainmatter")
            expect(mainmatter_chapters.first.position).to eq(1)

            mainmatter_titles = mainmatter_chapters.map(&:title)
            expect(mainmatter_titles).to eq(["Chapter 1"])

            backmatter_titles = chapter_repo.for_commit_and_part(commit, "backmatter").map(&:title)
            expect(backmatter_titles).to eq(["Appendix A: The First Appendix"])

            footnotes = footnote_repo.for_commit(commit)
            expect(footnotes.count).to eq(1)
            expect(footnotes.first.content).to include("Footnotes should appear at the end of chapters")
          end
        end

        context "with the Rails book", integration: true do
          let!(:book) do
            book_repo.create(
              permalink: "rails-4-in-action",
              title: "Rails 4 in Action",
              github_user: "rubysherpas",
              github_repo: "rails_book",
            )
          end

          let!(:branch) { book_repo.add_branch(book, name: "master") }

          it "can process the book" do
            subject.perform(
              "permalink" => book.permalink,
              "branch" => branch.name,
              "github_path" => "rubysherpas/rails_book",
            )

            commit = commit_repo.latest_for_branch(branch.id)

            frontmatter_titles = chapter_repo.for_commit_and_part(commit, "frontmatter").map(&:title)
            expect(frontmatter_titles).to eq(["Preface", "Acknowledgements", "About this book"])

            mainmatter_titles = chapter_repo.for_commit_and_part(commit, "mainmatter").map(&:title)
            expect(mainmatter_titles).to include("Ruby on Rails, the framework")

            backmatter_titles = chapter_repo.for_commit_and_part(commit, "backmatter").map(&:title)
            expect(backmatter_titles).to eq(["Appendix A: Installation Guide", "Appendix B: Why Rails?"])
          end
        end
      end
    end
  end
end
