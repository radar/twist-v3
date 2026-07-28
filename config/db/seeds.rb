# This seeds file should create the database records required to run the app.
#
# The code should be idempotent so that it can be executed at any time.
#
# To load the seeds, run `hanami db seed`. Seeds are also loaded as part of `hanami db prepare`.

# For example, if you have appropriate repos available:
#
#   category_repo = Hanami.app["repos.category_repo"]
#   category_repo.create(title: "General")
#
# Alternatively, you can use relations directly:
#
#   categories = Hanami.app["relations.categories"]
#   categories.insert(title: "General")

user_repo = Hanami.app["repos.user_repo"]
user = user_repo.create(name: "Ryan", email: "me@ryanbigg.com", password: "password")

book_repo = Hanami.app["repos.book_repo"]
# book = book_repo.create(
#   permalink: "asciidoc-book-test",
#   title: "Asciidoc Book Test",
#   github_user: "radar",
#   github_repo: "asciidoc_book_test",
# )

book = book_repo.create(
  permalink: "dev-dev-dev",
  title: "Developers Developing Developers",
  github_user: "radar",
  github_repo: "devdevdev",
)

book_repo.grant_permission(book:, user:)
