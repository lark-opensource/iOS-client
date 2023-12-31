module Fastlane
  module Actions
    module SharedValues
      RELEASE_NOTES = :RELEASE_NOTES
    end

    class GenerateReleaseNoteAction < Action
      def self.run(params)
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
          
          default_branch = body['default_branch']
          UI.success("Successfully get default branch: #{default_branch}")

          # 获取最近的两个tag信息
          GitlabGetTagListAction.run(
              api_token: params[:api_token],
              api_url: params[:api_url],
              project_id: params[:project_id],
              order_by: 'updated',
              sort: 'desc',
          ) do |tag_list|
            current_tag = tag_list['current_tag']
            current_tag_name = current_tag['name']
            current_tag_description = current_tag['release'].to_s.strip.length == 0 ? '' : current_tag['release']['description']
            current_tag_commit_id = current_tag['commit']['id']
            current_tag_commit_title = current_tag['commit']['title']
            current_tag_commit_created = current_tag['commit']['created_at']

            previous_tag = tag_list['previous_tag']
            if previous_tag.to_s.strip.length != 0 
              previous_tag_name = previous_tag['name']
              previous_tag_description = previous_tag['release'].to_s.strip.length == 0 ? '' : previous_tag['release']['description']
              previous_tag_commit_id = previous_tag['commit']['id']
              previous_tag_commit_title = previous_tag['commit']['title']
              previous_tag_commit_created = previous_tag['commit']['created_at']
              previous_tag_commit_created = Time.parse(previous_tag_commit_created) + 1
            end

            # 转换时间
            current_tag_commit_created_locale = Time.parse(current_tag_commit_created).localtime
            previous_tag_commit_created_locale = Time.parse("#{previous_tag_commit_created}").localtime

            UI.success("current_tag_name: #{current_tag_name}\ncurrent_tag_commit_title: #{current_tag_commit_title}\ncurrent_tag_commit_created: #{current_tag_commit_created}\ncurrent_tag_commit_created_locale: #{current_tag_commit_created_locale}")
            UI.success("previous_tag_name: #{previous_tag_name}\nprevious_tag_commit_title: #{previous_tag_commit_title}\nprevious_tag_commit_created: #{previous_tag_commit_created}\nprevious_tag_commit_created_locale: #{previous_tag_commit_created_locale}")

            GitlabGetCommitListAction.run(
              api_token: params[:api_token],
              api_url: params[:api_url],
              project_id: params[:project_id],
              ref_name: default_branch,
              since: previous_tag_commit_created,
              until: current_tag_commit_created
            ) do |commit_list|
              release_notes = ""
              release_added_title = "###### Added\r\n"
              release_added_content = ""
              release_fixed_title = "###### Fixed\r\n"
              release_fixed_content = ""
              release_changed_title = "###### Changed\r\n"
              release_changed_content = ""

              idx = 1
              for index in 0 ... commit_list.size
                commit_body = commit_list[index]

                title = commit_body['title']
                short_id = commit_body['short_id']
                description = commit_body['message']
                committed_date = commit_body['committed_date']
                committed_date = Time.parse(committed_date).localtime

                value = title
                if value.to_s.strip.length != 0 
                  current_staing = ""
                  if value =~ /feature/i or value =~ /feat/i
                    current_staing = "added"
                  elsif value =~ /bugfix/i or value =~ /fix/i
                    current_staing = "fixed"
                  else
                    current_staing = "changed"
                  end
                  if !(value =~ /Merge branch '/)
                    if current_staing == "added"
                      release_added_content = release_added_content + "- " + value + '   ' + "【#{short_id} / #{committed_date}】" + "\r\n"
                    elsif current_staing == "fixed"
                      release_fixed_content = release_fixed_content + "- " + value + '   ' + "【#{short_id} / #{committed_date}】" + "\r\n"
                    elsif current_staing == "changed"
                      release_changed_content = release_changed_content + "- " + value + '   ' + "【#{short_id} / #{committed_date}】" + "\r\n"
                    end
                  end
                end
                idx += 1
              end

              if release_added_content.to_s.strip.length != 0 
                release_notes += (release_added_title + release_added_content)
              end
              if release_fixed_content.to_s.strip.length != 0 
                release_notes += (release_fixed_title + release_fixed_content)
              end
              if release_changed_content.to_s.strip.length != 0 
                release_notes += (release_changed_title + release_changed_content)
              end

              Actions.lane_context[SharedValues::RELEASE_NOTES] = release_notes
              UI.success("release_notes: #{release_notes}")

              if params[:post] == true
                # 更新tag release notes
                http_method = ''
                if current_tag_description.to_s.strip.length == 0
                  http_method = 'post'
                else 
                  http_method = 'put'
                end
                Actions::GitlabUpdateTagInfoAction.run(
                  http_method: http_method,
                  api_token: params[:api_token],
                  api_url: params[:api_url],
                  project_id: params[:project_id],
                  tag_name: current_tag_name,
                  description: release_notes
                )
              end
            end
          end
        else
          UI.error("Error get default branch: #{response[:status]}: #{response[:body]}")
        end
      end

      #####################################################
      # @!group Documentation
      #####################################################

      def self.description

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
          FastlaneCore::ConfigItem.new(key: :post,
                                       description: "",
                                       default_value: true,
                                       is_string: false,
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
        [
   
        ]
      end

      def self.category
        :source_control
      end

    end
  end
end