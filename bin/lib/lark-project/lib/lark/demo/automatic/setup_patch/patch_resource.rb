# frozen_string_literal: true

module Lark
  module Demo
    require 'xcodeproj'

    class Automatic
      class SetupPatcher
        require 'pathname'

        # 对 proj 补充 resource，目前主要是 lark_settings
        def patch_resource
#          file_path = auto_dir.join('lark_settings')
#          raise "patch source file failed, #{file_path} does not exist." unless file_path.exist?
#
#          file_ref = auto_group.new_file(file_path)
#          main_target.resources_build_phase.add_file_reference(file_ref)
        end
      end
    end
  end
end
