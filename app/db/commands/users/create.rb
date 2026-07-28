module Twist
  module DB
    module Commands
      module Users
        class Create < ROM::Commands::Create[:sql]
          relation :users
          register_as :create
          result :one

          use :timestamps
          timestamps :created_at, :updated_at
        end
      end
    end
  end
end
