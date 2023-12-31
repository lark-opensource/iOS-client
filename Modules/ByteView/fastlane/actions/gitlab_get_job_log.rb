module Fastlane
  module Actions
    class GitlabGetJobLogAction < Action
      def self.run(params)

        url = "#{params[:api_url]}/projects/#{params[:project_id]}/jobs/#{params[:job_id]}/trace"
        headers = {
          'Content-Type' => 'application/json'
        }
        headers['PRIVATE-TOKEN'] = params[:api_token]
        http_method = 'get'

        connection = Excon.new(url)
        response = connection.request(
          method: http_method,
          headers: headers,
          debug_request: true,
          debug_response: true
        )

        if response[:status].between?(200, 299)
          UI.success("Successfully get job log: #{response}")

          reason = ""
          line_count = 0

          if params[:code] == "2"
            response.body.each_line do |line|
              if line.to_s.force_encoding("UTF-8").include? "❌"
                UI.success("Found build fail message, line reason: #{line}")
                reason += line
                line_count += 1
                if line_count == 10
                  break
                end
              end
            end

            if line_count == 0
              response.body.each_line do |line|
                if line.to_s.force_encoding("UTF-8").include? "xcodebuild -showBuildSettings timed out after"
                  UI.success("Found build fail message, line reason: #{line}")
                  reason += line
                  break
                end
              end
            end
          else
            pod_log_array = []
            contain_fail_message = false
            if params[:code] == "1"
              message_to_found = params[:fail_pod_message]
            elsif params[:code] == "3"
              message_to_found = params[:fail_fetch_message]
            elsif params[:code] == "4"
              message_to_found = params[:fail_pull_message]
            end
            UI.success("Message_to_found: #{message_to_found}")
            response.body.each_line do |line|
              if !line.to_s.force_encoding("UTF-8").include? "#{message_to_found}"
                # UI.success("Not found fail message, line reason: #{line}")
                pod_log_array.push(line)
              else
                UI.success("Found fail message, line reason: #{line}")
                contain_fail_message = true
                break
              end
            end

            filter_count = params[:fail_filter_count].to_i
            UI.success("Filter_count: #{filter_count}")
            if contain_fail_message && pod_log_array.length >= filter_count
              pod_log_array = pod_log_array.last(filter_count)
              reason = pod_log_array.join("")
            end
          end

          reason = reason.to_s.force_encoding("UTF-8")
          UI.success("Fail reason is: #{reason}")
          yield(reason) if block_given?
        else
          UI.error("Error get job log: #{response[:status]}, #{response[:body]}")
        end
      end


      #####################################################
      # @!group Documentation
      #####################################################

      def self.description
        "Get job log"
      end

      def self.available_options
        [
          FastlaneCore::ConfigItem.new(key: :api_token,
                                       env_name: "GITLAB_PRIVATE_TOKEN",
                                       description: "Personal API Access Token for GitLab",
                                       sensitive: true,
                                       is_string: true,
                                       optional: false),
          FastlaneCore::ConfigItem.new(key: :api_url,
                                       env_name: "GITLAB_API_BASE_URL",
                                       description: "The URL of GitLab API",
                                       is_string: true,
                                       optional: false),
          FastlaneCore::ConfigItem.new(key: :project_id,
                                       env_name: "CI_PROJECT_ID",
                                       description: "The id of the project",
                                       is_string: true,
                                       optional: false),
          FastlaneCore::ConfigItem.new(key: :job_id,
                                       env_name: "CI_JOB_ID",
                                       description: "The id of job",
                                       is_string: true,
                                       optional: false),
          FastlaneCore::ConfigItem.new(key: :fail_fetch_message,
                                       env_name: "LARK_PACKAGE_FAIL_FETCH_MESSAGE",
                                       description: "Fail fetch message",
                                       is_string: true,
                                       optional: true),
          FastlaneCore::ConfigItem.new(key: :fail_pull_message,
                                       env_name: "LARK_PACKAGE_FAIL_PULL_MESSAGE",
                                       description: "Fail pull message",
                                       is_string: true,
                                       optional: true),
          FastlaneCore::ConfigItem.new(key: :fail_pod_message,
                                       env_name: "LARK_PACKAGE_FAIL_POD_MESSAGE",
                                       description: "Fail pod message",
                                       is_string: true,
                                       optional: true),
          FastlaneCore::ConfigItem.new(key: :fail_build_message,
                                       env_name: "LARK_PACKAGE_FAIL_BUILD_MESSAGE",
                                       description: "Fail build message",
                                       is_string: true,
                                       optional: true),
          FastlaneCore::ConfigItem.new(key: :fail_filter_count,
                                       env_name: "LARK_PACKAGE_FILTER_COUNT",
                                       description: "Fail filter count",
                                       is_string: true,
                                       optional: true),
          FastlaneCore::ConfigItem.new(key: :code,
                                       description: "The error code",
                                       is_string: false,
                                       optional: false)
        ]
      end

      def self.output

      end

      def self.return_value
        # If you method provides a return value, you can describe here what it does
      end

      def self.authors
        ['yangyao.wildyao@bytedance.com']
      end

      def self.is_supported?(platform)
        return true
      end

       def self.example_code

      end

      def self.category
        :source_control
      end

    end
  end
end