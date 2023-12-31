require 'cocoapods'

module Pod
  class Sandbox
    class PathList
      define_method(:read_file_system) do |*args|
        unless root.exist?
          raise Informative, "Attempt to read non existent folder `#{root}`."
        end
        dirs = []
        files = []
        root_length = root.cleanpath.to_s.length + File::SEPARATOR.length
        escaped_root = escape_path_for_glob(root)

        symlink_dirs = Dir.entries(escaped_root).select do | entry|
          File.directory?(escaped_root.to_s + '/' + entry) && File.symlink?(escaped_root.to_s + '/' + entry)
        end
        all_files_in_symlink_dirs = symlink_dirs.map do |dir|
          Dir.glob(escaped_root.to_s + '/' + dir + '/' + '**/*', File::FNM_DOTMATCH)
        end
        all_files_in_symlink_dirs.flatten!.each do |f|
          directory = File.directory?(f)
          # Ignore `.` and `..` directories
          next if directory && f =~ /\.\.?$/

          f = f.slice(root_length, f.length - root_length)
          next if f.nil?

          (directory ? dirs : files) << f
        end

        Dir.glob(escaped_root + '**/*', File::FNM_DOTMATCH).each do |f|
          directory = File.directory?(f)
          # Ignore `.` and `..` directories
          next if directory && f =~ /\.\.?$/

          f = f.slice(root_length, f.length - root_length)
          next if f.nil?

          (directory ? dirs : files) << f
        end

        dirs.sort_by!(&:upcase)
        files.sort_by!(&:upcase)

        @dirs = dirs
        @files = files
        @glob_cache = {}
      end
    end
  end
end
