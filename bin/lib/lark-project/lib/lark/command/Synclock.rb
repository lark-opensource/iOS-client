require 'cocoapods'
require_relative '../project/lockfile'

module Pod
  class Commands
    class Synclock < Command
      # def initialize(argv)
      #   super(argv)
      # end

      def run
        Lark::Project::Lockfile.checkout_lockfile
      end
    end
  end
end
