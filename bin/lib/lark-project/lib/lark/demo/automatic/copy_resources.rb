module Lark
  module Demo
    class Automatic
      require 'fileutils'

      # Copy lark-demo 所需的 resources。目前包括：lark_settings, Podfile.strict.lock
      #
      # @type ios_client_dir [Pathname] ios-client 根目录
      # @type lark_project_dir [Pathname] lark-project 根目录
      def self.copy_resources(ios_client_dir:, lark_project_dir:)
        target_resource_dir = lark_project_dir.join('lib/lark/demo/automatic/resource')
        raise "[lark-demo] copy resource failed. #{target_resource_dir} does not exist" unless target_resource_dir

        # copy Podfile.strict.lock
        lockfile_path = lark_project_dir.join('config/Podfile.strict.lock')
        raise "[lark-demo] copy lark_settings failed. #{lark_settings_path} does not exist" unless lockfile_path
        puts "copying Podfile.strict.lock from #{lockfile_path} to #{target_resource_dir}"
        FileUtils.cp(lockfile_path, target_resource_dir)
      end

    end
  end
end
