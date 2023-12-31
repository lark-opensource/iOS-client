# frozen_string_literal: true

module Lark
  module Demo
    class Automatic
      class SetupPatcher
        require 'fileutils'
        require_relative '../../util'

        def patch_podfile
          # write Podfile
          template = File.read(resource_dir.join'Podfile')
          content = Utils.render(template, { :proj_name => @proj.root_object.name, :pods => @options[:pods] || [] })
          to_path = @proj.project_dir.join('Podfile')
          FileUtils.rm_f(to_path) if to_path.exist?
          File.write(@proj.project_dir.join('Podfile'), content)

          # write Podfile.strict.lock
          from_path = resource_dir.join('Podfile.strict.lock')
          to_path = @proj.project_dir.join('Podfile.strict.lock')
          FileUtils.rm_f(to_path) if to_path.exist?
          FileUtils.cp(from_path, to_path)
        end
      end
    end
  end
end

