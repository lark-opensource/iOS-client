# frozen_string_literal: true

module Lark
  module Demo
    class Automatic
      module EntryWriter
        require_relative './write_base_gemfile'
        require_relative './write_base_podfile'
        require_relative './write_lark_settings'
        require_relative './write_changelog'
      end
    end
  end
end
