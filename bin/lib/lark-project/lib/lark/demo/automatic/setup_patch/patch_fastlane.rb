# frozen_string_literal: true

module Lark
  module Demo
    class Automatic
      class SetupPatcher
        require 'fileutils'
        require_relative '../../util'

        # 生成 fastlane，目录结构：
        # - fastlane/
        #   - Fastfile
        #   - Appfile
        def patch_fastlane
          # make dir `fastlane/` if not exist
          fastlane_dir = @proj.project_dir.join('fastlane')
          Dir.mkdir(fastlane_dir) unless fastlane_dir.exist?

          # write `fastlane/Fastfile` if not exist
          file_name = 'Fastfile'
          File.write(
            fastlane_dir.join(file_name),
            Utils.render(File.read(resource_dir.join(file_name)), {
              :proj_name => @proj.root_object.name,
              :schema_name => @proj.root_object.name
            })
          ) unless fastlane_dir.join(file_name).exist?

          # write `fastlane/Appfile` if not exist
          file_name = 'Appfile'
          from_path, to_path = resource_dir.join(file_name), fastlane_dir.join(file_name)
          FileUtils.cp(from_path.to_s, to_path.to_s) unless to_path.exist?
        end
      end
    end
  end
end
