module Fastlane
  module Actions
    class GitlabGetTagListAction < Action
      def self.run(params)

        tag_info = self.get_tag_info(params)
        yield(tag_info) if block_given?
      end

      def self.get_tag_info(params) 
        require 'excon'
      
        url = "#{params[:api_url]}/projects/#{params[:project_id]}/repository/tags?order_by=#{params[:order_by]}&sort=#{params[:sort]}"
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
          # UI.success("Successfully get tag list: #{body}")
          UI.success("Successfully get tag list")

          if !body.empty? && body.count >= 2
            # 获取两个tag，之后获取两个tag的commit时间，获取这两个时间之内的merge request信息
            idx = 0
            current_tag = body.at(idx)
            previous_tag = body.at(idx+1)
            UI.success("current_tag: #{current_tag}")
            UI.success("previous_tag: #{previous_tag}")

            returns = {
              'current_tag' => current_tag,
              'previous_tag' => previous_tag
            }
            return returns
          else 
            UI.error("get tag list body empty!")
          end
        elsif !body.empty? && body.count == 1
          current_tag = body.at(0)
          UI.success("current_tag: #{current_tag}")

          returns = {
            'current_tag' => current_tag
          }
          return returns
        else
          UI.error("Error get tag list: #{response[:status]}: #{response[:body]}")
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
          FastlaneCore::ConfigItem.new(key: :order_by,
                                       description: "",
                                       default_value: 'updated',
                                       is_string: true,
                                       optional: true),
          FastlaneCore::ConfigItem.new(key: :sort,
                                       description: "",
                                       default_value: 'desc',
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