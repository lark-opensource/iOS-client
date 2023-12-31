# frozen_string_literal: true

module Lark
  module Demo
    class Automatic
      module EntryWriter
        require_relative '../../util'

        # 写入 BaseGemfile 内容
        #
        # @param target_path [Pathname] The target
        # @param proj_name [String]
        # @param gem_versions [Hash<String, String>]
        def self.write_base_gemfile(target_path, proj_name:, gem_versions:)
          template = File.read(File.expand_path('../resource/BaseGemfile', __dir__))
          content = Utils.render(template, { :proj_name => proj_name, :gem_versions => gem_versions })
          File.write(target_path.to_s, content)
        end
      end
    end
  end
end
