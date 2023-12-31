# frozen_string_literal: true

require 'xcodeproj'

module Lark
  module Demo
    class Automatic
      class UpdatePatcher
        # @param proj [Xcodeproj::Project]
        def initialize(proj)
          @proj = proj
        end

        # @return [Xcodeproj::Project::PBXNativeTarget]
        def main_target
          @proj.targets.first
        end

        # @return [Xcodeproj::Project::PBXGroup]
        def auto_group
          @auto_group ||= begin
                            group = @proj.main_group.groups.find { |g| g.name == AUTO_GROUP_NAME }
                            group ||= @proj.new_group(AUTO_GROUP_NAME)
                            group
                          end
        end

        def run
          # 待完善补充...
        end
      end
    end
  end
end

