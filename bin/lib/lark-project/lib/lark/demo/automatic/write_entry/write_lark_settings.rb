# frozen_string_literal: true

module Lark
  module Demo
    class Automatic
      module EntryWriter
        require 'fileutils'

        # 写入 lark_settings
        #
        # @param target_path [Pathname]
        def self.write_lark_settings(target_path)
          # FileUtils.cp(File.expand_path('../resource/lark_settings', __dir__), target_path.to_s)
        end
      end
    end
  end
end
