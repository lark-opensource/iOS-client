# frozen_string_literal: true

require 'http'
require 'fileutils'
require 'logger'

# this class responsible for upload Gecko resource to rosetta
# see https://bytedance.feishu.cn/docs/doccn0DDdBRJlWRnc6bnKebxSWc#
# FIXME: broken, WIP to implement this feature..
class UploadLangs
  HOST = 'http://10.253.4.177:6000'
  UploadModule = '/api/v1/module_versions'
  UploadPackage = '/api/v1/packages'

  # @param gecko_root [String] normally at Pods/.Gecko
  def initialize(gecko_root, project, version)
    @root = gecko_root
    @project = project
    @version = version

    @logger = Logger.new(STDOUT)
    @logger.level = Logger::Info
  end

  def run!
    # FIXME: 小程序目前没有提供meta
    metas = Dir.glob("#{@root}/*/meta.json")
    Dir.mktmpdir('gecko') do |output_root|
      metas.each do |meta|
        upload_module meta, output_root
      end
      form = {
        project: @project,
        version: @version,
        env: 'test',
        platform: 'iOS',
        description: "#{@project}(#{@version}) on-demand package"
      }
      @logger.info "upload package for #{form}"
      check_response client.post(UploadPackage, form: form), UploadPackage
    ensure
      @client&.close
    end
  end

  def upload_module(meta, output_root)
    root = File.dirname meta
    module_name = File.basename(root, '.*')
    resource_dir = root
    output_path = File.join(output_root, "#{module_name}.zip")

    # 和Rosetta商量的zip里不含目录，直接放strings资源
    cmd = %(zip -qjr "#{output_path}" "#{resource_dir}"/*.strings*)
    @logger.debug(cmd)
    raise "zip failed: #{cmd}" unless system(cmd)

    @logger.info "upload module #{module_name}"
    form = {
      project: @project,
      module: module_name,
      version: @version,
      platform: 'iOS',
      config_file: HTTP::FormData::File.new(meta),
      resource_file: HTTP::FormData::File.new(output_path)
    }
    check_response client.post(UploadModule, form: form), UploadModule
  end

  # @return [HTTP::Client]
  def client
    @client ||= HTTP.use(logging: { logger: @logger }).persistent(HOST)
  end

  # @param response [HTTP::Response]
  def check_response(response, url)
    raise "url: <#{url}>\nresponse: #{format_response_error(response)}" unless response.status.success?
  end

  # @param response [HTTP::Response]
  def format_response_error(response)
    status = "< #{response.status}"
    headers = response.headers.map { |name, value| "#{name}: #{value}" }.join("\n")
    body = response.body.to_s

    [status, headers, '', body].join("\n")
  end
end
