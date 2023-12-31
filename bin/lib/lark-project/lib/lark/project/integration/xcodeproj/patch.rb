# frozen_string_literal: true

require 'xcodeproj'

module Xcodeproj
  class Project
    class UUIDGenerator
      if $verify_no_duplicates_uuid
        define_method(:verify_no_duplicates!) do |all_objects, all_new_objects|
          duplicates = all_objects - all_new_objects
          unless duplicates.empty?
            UserInterface.warn(+"[Xcodeproj] Generated duplicate UUIDs:\n\n" <<
                               duplicates.map { |d| "#{d.isa} -- #{@paths_by_object[d]}" }.join("\n"))
            if defined? ::Pod::UI
              ::Pod::UI.print_warnings 
              ::Pod::UI.warnings = []
            end
            error = duplicates.map do |d|
              name = %i[display_name name uuid].find { |n| break d.send(n) if d.respond_to? n }
              "#{d.project.root_object.name}: #{d.isa} - #{name}"
            end
            raise "Duplicate UUID: #{error.join("\n")}"
          end
        end
      end
    end
  end
end
