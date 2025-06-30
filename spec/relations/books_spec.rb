require 'spec_helper'

RSpec.describe Twist::Repos::BookRepo do
  let(:book_repo) { Hanami.app["repos.book_repo"] }
  let(:branch_repo) { Hanami.app["repos.branch_repo"] }
  let(:commit_repo) { Hanami.app["repos.commit_repo"] }

  before do
    book = book_repo.create(
      title: "Test Book",
      permalink: "test-book",
    )

    branch = branch_repo.create(
      name: "master",
      book_id: book.id,
      default: true
    )

    commit_repo.create(
      sha: "abc123",
      branch_id: branch.id,
      message: "Initial commit",
    )
  end

  it "creates a default branch for a book" do
    book = book_repo.find_by_permalink_with_default_branch("test-book")
    binding.irb
  end
end
