module Users
  class Slice < Hanami::Slice
    config.views.paths = [
      File.expand_path("../../app/templates", __dir__),
      File.expand_path("../../slices/users/templates", __dir__),
    ]
  end
end
