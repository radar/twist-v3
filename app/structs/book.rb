module Twist
  module Structs
    class Book < ROM::Struct
      attribute :id, Types::Integer
      attribute :permalink, Types::String
      attribute :format, Types::String

      def path
        git = Git.new(
          username: github_user,
          repo: github_repo,
        )
        git.local_path
      end
    end
  end
end
