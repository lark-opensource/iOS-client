module Fastlane
  module Actions
    class GitlabMergeRequestInfoAction < Action
      def self.mr_detail(params, headers, iid, id)
        response = Excon.new("#{params[:api_url]}/projects/#{params[:project_id]}/merge_requests/#{iid}?id=#{id}&iid=#{iid}").request(
              method: 'get',
              headers: headers,
              debug_request: true,
              debug_response: true
            )
        if response[:status].between?(200, 299)
          body = JSON.parse(response.body)
          UI.success("Successfully get single merge request info: #{body}")
          return body
        end
      end

      def self.run(params)
        # url = "#{params[:api_url]}/projects/#{params[:project_id]}/merge_requests?state=merged&target_branch=#{params[:target_branch]}&order_by=updated_at&updated_before=#{params[:updated_before]}&updated_after=#{params[:updated_after]}"

        url = "#{params[:api_url]}/projects/#{params[:project_id]}/merge_requests?state=merged&order_by=created_at&target_branch=#{params[:target_branch]}"

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
          UI.success("Successfully get merge request info: #{body}")

          mrs = Array.new 
          for index in 0 ... body.size
            each_body = body[index]

            id = each_body['id']
            iid = each_body['iid']

            res = self.mr_detail(params, headers, iid, id)
            merged_at = res['merged_at']
            if "#{merged_at}" > "#{params[:updated_after]}" == true and "#{merged_at}" > "#{params[:updated_before]}" == false 
              mrs.push(res)
            else
              break
            end
          end

          if mrs.size > 1
            mrs.shift
          end
            
          release_notes = ""
          release_added_title = "#### Added\r\n"
          release_added_content = ""
          release_fixed_title = "#### Fixed\r\n"
          release_fixed_content = ""
          release_changed_title = "#### Changed\r\n"
          release_changed_content = ""

          idx = 1
          for index in 0 ... mrs.size
            merge_body = mrs[index]

            title = merge_body['title']
            description = merge_body['description']
            labels = merge_body['labels']
            commit_id = merge_body['sha']

            if description.to_s.strip.length != 0 
              current_staing = ""
              description.each_line do |line|
                if line.to_s.strip.length != 0 
                  if line =~ /#####|####|###|##|#/ and (line =~ /feature/i)
                    current_staing = "added"
                  elsif line =~ /#####|####|###|##|#/ and (line =~ /bugfix/i or line =~ /fix/i  or line =~ /bug/i)
                    current_staing = "fixed"
                  elsif line =~ /#####|####|###|##|#/ and (line =~ /other/i or line =~ /others/ii)
                    current_staing = "changed"
                  else
                    if current_staing == "added"
                      release_added_content = release_added_content + line
                    elsif current_staing == "fixed"
                      release_fixed_content = release_fixed_content + line
                    elsif current_staing == "changed"
                      release_changed_content = release_changed_content + line
                    end
                  end
                end
              end
            end
            idx += 1
          end

          if release_added_content.to_s.strip.length != 0 
            release_notes += (release_added_title + release_added_content + "\r\n")
          end
          if release_fixed_content.to_s.strip.length != 0 
            release_notes += (release_fixed_title + release_fixed_content + "\r\n")
          end
          if release_changed_content.to_s.strip.length != 0 
            release_notes += (release_changed_title + release_changed_content + "\r\n")
          end

          Actions.lane_context[SharedValues::RELEASE_NOTES] = release_notes
          UI.success("release_notes: #{release_notes}")

    
          yield(release_notes) if block_given?
          return release_notes
        else
          UI.error("Error get merge request info: #{response[:status]}: #{response[:body]}")
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
          FastlaneCore::ConfigItem.new(key: :target_branch,
                                       description: "",
                                       default_value: '',
                                       is_string: true,
                                       optional: false),
          FastlaneCore::ConfigItem.new(key: :updated_after,
                                       description: "",
                                       is_string: true,
                                       optional: false),
          FastlaneCore::ConfigItem.new(key: :updated_before,
                                       description: "",
                                       is_string: true,
                                       optional: true)


        ]
      end

      def self.output
        [
          ['RELEASE_MESSAGE', 'release message of tag'],
          ['RELEASE_NOTES', 'release notes of tag']
        ]
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