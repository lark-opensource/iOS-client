# frozen_string_literal: true

module Lark
  module Demo
    class Automatic
      class SetupPatcher
        require 'fileutils'

        def patch_gemfile
          from_path = resource_dir.join('Gemfile')
          to_path = @proj.project_dir.join('Gemfile')
          FileUtils.rm_f(to_path) if to_path.exist?
          FileUtils.cp(from_path, to_path)
        end
      end
    end
  end
end