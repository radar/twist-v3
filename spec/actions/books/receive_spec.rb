# frozen_string_literal: true
require "spec_helper"

RSpec.describe Twist::Actions::Books::Receive do
  let(:params) do
    {
      permalink: "exploding-rails",
      payload: {
        ref: "refs/heads/master",
        repository: {
          full_name: "radar/exploding_rails",
        },
      }.to_json
    }
  end

  context "when a markdown book exists" do
    let(:find_or_create_branch) do
      ->(book_id:, ref:) { branch }
    end

    let(:find_book) do
      ->(permalink:) { book }
    end

    let(:book) { double(Twist::Structs::Book, id: 1, permalink: "exploding-rails", format: "markdown") }
    let(:branch) { double(Twist::Structs::Branch, name: "master", username: "radar", repo: "exploding_rails") }

    subject do
      described_class.new(
        find_or_create_branch: find_or_create_branch,
        find_book: find_book,
      )
    end

    it "enqueues the markdown worker" do
      expect(Twist::Processors::Markdown::BookWorker).to receive(:perform_async)
            .with(
              permalink: "exploding-rails",
              branch: "master",
              username: "radar",
              repo: "exploding_rails",
            )
      response = subject.call(params)
      expect(response).to be_successful
    end
  end

  context "when an asciidoc book exists" do
    let(:receive_book) do
      ->(permalink:, branch_name:) { true }
    end

    let(:book) { double(Twist::Structs::Book, id: 1, permalink: "exploding-rails", format: "asciidoc") }
    let(:branch) { double(Twist::Structs::Branch, name: "master", username: "radar", repo: "exploding_rails") }

    subject do
      described_class.new(receive_book: receive_book)
    end

    it "enqueues the asciidoc worker" do
      expect(receive_book).to receive(:call).with(permalink: "exploding-rails", branch_name: "refs/heads/master")
      response = subject.call(params)
      expect(response).to be_successful
    end
  end

  context "when the book does not exist" do
    let(:find_book) do
      ->(permalink:) { nil }
    end

    subject do
      described_class.new(
        find_book: find_book,
      )
    end

    it "reports back the book cannot be found" do
      status, _, body = subject.(params)
      expect(status).to eq(404)
      expect(JSON.parse(body.first)).to eq("error" => "Book not found")
    end
  end
end


# require "spec_helper"

# describe Twist::Web::Controllers::Books::Receive do
#   let(:find_or_create_branch) do
#     ->(book_id:, ref:) { branch }
#   end

#   subject do
#     described_class.new(
#       find_or_create_branch: find_or_create_branch,
#       find_book: find_book,
#     )
#   end

#   let(:params) do
#     {
#       permalink: "exploding-rails",
#       payload: {
#         ref: "refs/heads/master",
#         repository: {
#           full_name: "radar/exploding_rails",
#         },
#       }.to_json
#     }
#   end

#   context "when book exists" do
#     let(:find_book) do
#       ->(permalink:) { book }
#     end

#     context "and the book is a markdown book" do
#       let(:book) { double(Twist::Entities::Book, id: 1, permalink: "exploding-rails", format: "markdown") }
#       let(:branch) { double(Twist::Entities::Branch, name: "master") }

#       it "triggers an update" do
        # expect(Twist::Processors::Markdown::BookWorker).to receive(:perform_async)
        #   .with(
        #     permalink: "exploding-rails",
        #     branch: "master",
        #     username: "radar",
        #     repo: "exploding_rails",
        #   )
        # status, _, body = subject.(params)
        # expect(status).to eq(200)
        # expect(body.first).to eq("OK")
#       end
#     end

#     context "and the book is an asciidoc book" do
#       let(:book) { double(Twist::Entities::Book, id: 1, permalink: "exploding-rails", format: "asciidoc") }
#       let(:branch) { double(Twist::Entities::Branch, name: "master") }

#       it "triggers an update" do
#         expect(Twist::Processors::Asciidoc::BookWorker).to receive(:perform_async)
#           .with(
#             permalink: "exploding-rails",
#             branch: "master",
#             username: "radar",
#             repo: "exploding_rails",
#           )
#         status, _, body = subject.(params)
#         expect(status).to eq(200)
#         expect(body.first).to eq("OK")
#       end
#     end
#   end
# end
