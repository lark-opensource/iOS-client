module Fastlane
  module Actions
    class GitlabCreateMergeRequestAction < Action
      def self.run(params)
        require 'excon'

        headers = {
          'Content-Type' => 'application/json'
        }
        headers['PRIVATE-TOKEN'] = params[:api_token]
        
        response = Excon.new("#{params[:api_url]}/projects/#{params[:project_id]}").request(
          method: 'get',
          headers: headers,
          debug_request: true,
          debug_response: true
        )
        
        if response[:status].between?(200, 299)
          body = JSON.parse(response.body)
          
          target_branch = body['default_branch']
          UI.success("Successfully get default branch: #{target_branch}")

          response = Excon.new("#{params[:api_url]}/projects/#{params[:project_id]}/merge_requests?state=opened").request(
            method: 'get',
            headers: headers,
            debug_request: true,
            debug_response: true
          )
        
          if response[:status].between?(200, 299)
            body = JSON.parse(response.body)
            UI.success("Successfully list opend merge request: #{body}")

            already_has_a_merge_request = false
            body.each { |merge| 
              if merge['source_branch'] == params[:ci_commit_ref_name]
                already_has_a_merge_request = true
              end
            }

            if already_has_a_merge_request == true
              UI.success("No new merge request opened")
            else 
              UI.success("Will open a new merge request: WIP: #{params[:ci_commit_ref_name]} and assigned to you")


              body = {
                'id' => params[:project_id],
                'source_branch' => params[:ci_commit_ref_name],
                'target_branch' => target_branch,
                'remove_source_branch' => true,
                'title' => "WIP: #{params[:ci_commit_ref_name]}",
                'assignee_id' => params[:assignee_id]
              }


              response = Excon.new( "#{params[:api_url]}/projects/#{params[:project_id]}/merge_requests").request(
                method: 'post',
                headers: headers,
                body: body.to_json,
                debug_request: true,
                debug_response: true
              )

              if response[:status].between?(200, 299)
                UI.success("Opened a new merge request: WIP: #{params[:ci_commit_ref_name]} and assigned to you")
              else 
                UI.error("Error open a new merge request: #{response[:status]}: #{response[:body]}")
              end
            end
          else  
            UI.error("Error list opend merge request: #{response[:status]}: #{response[:body]}")
          end
        else  
          UI.error("Error get default branch: #{response[:status]}: #{response[:body]}")
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
          FastlaneCore::ConfigItem.new(key: :ci_commit_ref_name,
                                       env_name: "CI_COMMIT_REF_NAME",
                                       description: "",
                                       is_string: true,
                                       optional: false),
          FastlaneCore::ConfigItem.new(key: :assignee_id,
                                       description: "",
                                       is_string: true,
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