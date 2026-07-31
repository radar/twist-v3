# frozen_string_literal: true

ROM::SQL.migration do
  up do
    alter_table :notes do
      add_foreign_key :book_id, :books, on_delete: :cascade
    end

    # Notes reach their book the long way around: element -> chapter -> commit ->
    # branch -> book. Every one of those keys is NOT NULL, so this covers them all.
    run <<~SQL
      UPDATE notes
      SET book_id = branches.book_id
      FROM elements, chapters, commits, branches
      WHERE elements.id = notes.element_id
        AND chapters.id = elements.chapter_id
        AND commits.id = chapters.commit_id
        AND branches.id = commits.branch_id
    SQL

    alter_table :notes do
      set_column_not_null :book_id
      add_index :book_id
    end
  end

  down do
    alter_table :notes do
      drop_column :book_id
    end
  end
end
