# frozen_string_literal: true
require "bcrypt"

module Twist
  module Repos
    class UserRepo < Twist::DB::Repo
      def create(user)
        user[:encrypted_password] = BCrypt::Password.create(user.delete(:password))
        user[:created_at] = Time.now.utc
        user[:updated_at] = Time.now.utc

        users.insert(user)
      end

      def authenticate(email, password)
        user = users.where(email: email).first
        return unless user

        return user if BCrypt::Password.new(user[:encrypted_password]) == password
      end

      def find(id)
        users.where(id: id).first
      end
    end
  end
end
