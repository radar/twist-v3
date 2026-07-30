# auto_register: false
# frozen_string_literal: true
#
require 'dotiw'

module Twist
  module Views
    module Helpers
      include DOTIW::Methods
      include RoutingHelpers
      include NoteHelpers
      include ChapterHelpers
    end
  end
end
