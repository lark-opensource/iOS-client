module Fastlane
  module Actions
    class GitlabGetCommitInfoAction < Action
      def self.run(params)
 
        url = "#{params[:api_url]}/projects/#{params[:project_id]}/repository/commits/#{params[:sha]}?stats=1"
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
          body = JSON.parse(response.body)
          UI.success("Successfully get single commit info: #{body}")
          yield(body) if block_given?
        else
          UI.error("Error get commit info: #{response[:status]}: #{response[:body]}")
        end
      end

  
      #####################################################
      # @!group Documentation
      #####################################################

      def self.description
        "Create a new merge request on GitLab"
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
          FastlaneCore::ConfigItem.new(key: :sha,
                                       description: "",
                                       default_value: '',
                                       is_string: true,
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