module OwnerConfig
  class Utils
    # 现阶段静默验证，并异步收集未知异常发送至 bot，一段时间后会下掉
    #
    # @param [Exception] error
    # @param [Symbol] mode
    def self.collect_error(error, mode:)
      case mode
      when :none
        return
      when :sync
        send_error_to_bot(error)
      when :async
        # 在后台线程发送错误信息到 bot, 不阻塞 pod install 流程
        Thread.new { send_error_to_bot(error) }
      else
        # 忽略
      end
    end

    # @param [Exception] error
    def self.send_error_to_bot(error)
      begin
        Net::HTTP.post(URI('https://ybtdkwqa.worker-fn.bytedance.net'),
                       {
                         name: error.class.to_s,
                         message: error.message,
                         backtrace: error.backtrace
                       }.to_json,
                       'Content-Type': 'application/json')
      rescue
        # 直接忽略网络请求产生的错误
      end
    end

    # @return [String]
    def self.project_root
      # noinspection RbsMissingTypeSignature
      @project_root ||=
        begin
          root = __FILE__
          root = File.dirname(root) until File.exist?(File.join(root, 'Podfile'))
          root
        end
    end

    # @return [Hash<String, String>]
    def self.pod_path_map
      config_path = File.join(project_root, ".bits/bits_components.yaml").to_s
      YAML.load_file(config_path)['components_publish_config']
          .map { |key, value| [key, value["archive_source_path"]] }
          .to_h
    end
  end
end
