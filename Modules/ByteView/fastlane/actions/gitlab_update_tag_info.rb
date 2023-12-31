module Fastlane
  module Actions
    class GitlabUpdateTagInfoAction < Action
      def self.run(params)
        require 'excon'

        url = "#{params[:api_url]}/projects/#{params[:project_id]}/repository/tags/#{params[:tag_name]}/release"
        headers = {
          'Content-Type' => 'application/json'
        }
        headers['PRIVATE-TOKEN'] = params[:api_token]
        body = {
          'description' => params[:description]
        }

        http_method = params[:http_method]
        connection = Excon.new(url)
        response = connection.request(
          method: http_method,
          headers: headers,
          body: body.to_json,
          debug_request: true,
          debug_response: true
        )

        # response = Excon.post(url, headers: headers, body: data.to_json)
        if response[:status].between?(200, 299)
          body = JSON.parse(response.body)
          UI.success("Successfully update tag release notes: #{body}")
        else
          UI.error("Error update tag release notes: #{response[:status]}: #{response[:body]}")
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
          FastlaneCore::ConfigItem.new(key: :http_method,
                                       description: "",
                                       default_value: '',
                                       is_string: true,
                                       optional: false),
          FastlaneCore::ConfigItem.new(key: :tag_name,
                                       description: "",
                                       default_value: '',
                                       is_string: true,
                                       optional: false),
          FastlaneCore::ConfigItem.new(key: :description,
                                       description: "",
                                       is_string: true,
                                       default_value: '',
                                       optional: true)

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