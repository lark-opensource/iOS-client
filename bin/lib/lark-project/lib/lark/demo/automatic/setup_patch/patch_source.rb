# frozen_string_literal: true

module Lark
  module Demo
    class Automatic
      class SetupPatcher
        require 'pathname'
        require 'xcodeproj'
        require 'lark/project/assembly'

        # 对 proj 补充 source，目前主要是 BaseAssembly.swift
        def patch_source
          file_path = Lark::Project::Assembly.new_file(auto_dir)
          raise "patch source file failed, #{file_path} does not exist." unless file_path.exist?

          file_ref = auto_group.new_file(file_path)
          main_target.source_build_phase.add_file_reference(file_ref)
        end
      end
    end
  end
end
