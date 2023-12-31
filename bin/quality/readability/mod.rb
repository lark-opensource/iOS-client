
require_relative './part'

class Mod < Part
  def name
    path
  end

  class << self
    def key_field_name
      '模块'
    end

    # @param [Part::Proj] proj
    # @param [String] repo_path
    # @return [Array<Pod>]
    def list_all(proj:, repo_path:) # rubocop:disable Metrics/MethodLength
      pods = []
      Dir.chdir(repo_path) do
        `find '#{proj.path}' -type f -name \\*.podspec`
          .lines(chomp: true)
          .each do |path|
          pod = Pod.new
          pod.name = File.basename(path, '.podspec')
          pod.path = Pathname(path).parent.to_s
          pod.proj = proj
          pods << pod
        end
      end
      pods
    end
  end
end