# frozen_string_literal: true

require 'xcodeproj'

module Lark
  module Demo
    class Automatic
      class SetupPatcher
        # @param proj [Xcodeproj::Project]
        def initialize(proj, **opt)
          @proj = proj
          @options = opt
        end

        # 存放资源/模板的目录
        #
        # @return [Pathname]
        def resource_dir
          Pathname.new(__dir__).join('../resource')
        end

        # @return [Pathname]
        def auto_dir
          @proj.project_dir.join Automatic::AUTO_DIR_NAME
        end

        # @return [Xcodeproj::Project::PBXNativeTarget]
        def main_target
          @proj.targets.first
        end

        # @return [Xcodeproj::Project::PBXGroup]
        def auto_group
          @auto_group ||= begin
                            group = @proj.main_group.groups.find { |g| g.name == Automatic::AUTO_GROUP_NAME }
                            group ||= @proj.new_group(Automatic::AUTO_GROUP_NAME)
                            group
                          end
        end

        require_relative './patch_source'
        require_relative './patch_resource'
        require_relative './patch_gemfile'
        require_relative './patch_podfile'
        require_relative './patch_fastlane'

        def run
          patch_source
          patch_resource
          patch_gemfile
          patch_podfile
          patch_fastlane

          @proj.save
        end
      end
    end
  end
end

