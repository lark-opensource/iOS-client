# frozen_string_literal: true

module Lark
  module Demo
    class Automatic
      module EntryWriter
        require 'fileutils'

        # 写入 changelog 内容
        #
        # @param target_path [Pathname] The target
        def self.write_changelog(target_path)
          FileUtils.cp(File.expand_path('../resource/changelog', __dir__), target_path.to_s)
        end
      end
    end
  end
end
