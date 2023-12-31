require 'fastlane_core/print_table'
module Fastlane
  module Actions
    module SharedValues
      LARK_BOT_DEBUG_INFO = :LARK_BOT_DEBUG_INFO
    end

    class LarkBotAction < Action
      def self.notify(params)
        # fastlane will take care of reading in the parameter and fetching the environment variable:
        require 'faraday'
        require 'faraday_middleware'

        url = params[:url]
        connection = Faraday.new(url) do |builder|
          builder.request(:json)
          builder.response(:json, content_type: /\bjson$/)
          builder.use(FaradayMiddleware::FollowRedirects)
          builder.adapter(:net_http)
        end

        options = {}
        options[:title] = "[iOS]构建成功: #{params[:username]}发布了#{params[:project_name]}, 平台: iOS, 版本: #{params[:app_version]}, 构建分支/tag: #{params[:ref_name]}"

        if params[:title]
          options[:title] = params[:title]
        end

        if params[:msg]
          options[:text] = params[:msg] + "\n"
        else
          GitlabGetCommitListAction.run(
              api_token: params[:api_token],
              api_url: params[:api_url],
              project_id: params[:project_id],
              ref_name: params[:ref_name],
              since: Time.now.gmtime - 24 * 3600,
              until: Time.now.gmtime
            ) do |commit_list|
              release_notes = ""
              release_added_title = "\n[呲牙]Added:\r\n"
              release_added_content = ""
              release_added_index = 1
              release_fixed_title = "\n[捂脸]Fixed:\r\n"
              release_fixed_content = ""
              release_fixed_index = 1
              release_changed_title = "\n[奸笑]Changed:\r\n"
              release_changed_content = ""
              release_changed_index = 1
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
                    time_format_string = committed_date.strftime("%Y-%m-%d %H:%M:%S")
                    if current_staing == "added"
                      release_added_content = release_added_content + "#{release_added_index}." + value + "\n         " + "(#{short_id} / #{time_format_string})" + "\r\n"
                      release_added_index += 1
                    elsif current_staing == "fixed"
                      release_fixed_content = release_fixed_content + "#{release_fixed_index}." + value + "\n         " + "(#{short_id} / #{time_format_string})" + "\r\n"
                      release_fixed_index += 1
                    elsif current_staing == "changed"
                      release_changed_content = release_changed_content + "#{release_changed_index}." + value + "\n         " + "(#{short_id} / #{time_format_string})" + "\r\n"
                      release_changed_index += 1
                    end
                  end
                end
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
              if release_notes.length > 0
                options[:text] = release_notes
                UI.success("release_notes: #{release_notes}")
              else
                options[:text] = "Lark为最新，但ByteView无代码改变\n"
                UI.success("release is empty")
            end
          end
        end

        if params[:link]
          options[:text] += "#{params[:link]}"
        end

  FastlaneCore::PrintTable.print_values(config: options,
      hide_keys: [],
      title: "Summary for lark_bot #{Fastlane::VERSION}")
        post_request = connection.post do |req|
          req.body = options
        end

        post_request.on_complete do |env|
          Actions.lane_context[SharedValues::LARK_BOT_DEBUG_INFO] = "#{env}"
        end
      end

      def self.run(params) 
        response = notify(params)
        case response.status
        when 200...300
          UI.success("send notify success!")
        else
          UI.user_error!("send notify failed with payload: #{response.body}")
        end
      end

      #####################################################
      # @!group Documentation
      #####################################################

      def self.description
        "发送lark通知"
      end

      def self.details
        # Optional:
        # this is your chance to provide a more detailed description of this action
        "向Lark通知机器人，发送信息"
      end


      def self.available_options
        # Define all options your action supports. 
        
        # Below a few examples
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
          FastlaneCore::ConfigItem.new(key: :project_name,
                                       env_name: "CI_PROJECT_NAME",
                                       description: "the project name should append to the title",
                                       is_string: true,
                                       optional: true),
          FastlaneCore::ConfigItem.new(key: :ref_name,
                                       env_name: "CI_COMMIT_REF_NAME",
                                       description: "the ref name",
                                       is_string: true,
                                       optional: true),
          FastlaneCore::ConfigItem.new(key: :title,
                                       description: "The title of Lark notify",
                                       is_string: true,
                                       optional: true),
          FastlaneCore::ConfigItem.new(key: :msg,
                                       description: "The message of Lark notify",
                                       is_string: true,
                                       optional: true),
          FastlaneCore::ConfigItem.new(key: :url,
                                       env_name: "LARK_NOTIFY_BOT_URL", # The name of the environment variable
                                       description: "The url of Lark notify bot", # a short description of this parameter
                                       is_string: true,
                                       verify_block: proc do |value|
                                          UI.user_error!("No Lark notify bot url given, pass using `url: 'url'`") unless (value and not value.empty?)
                                       end),
          FastlaneCore::ConfigItem.new(key: :app_version,
                                       description: "The app version of the project",
                                       default_value: '',
                                       is_string: true,
                                       optional: false),
          FastlaneCore::ConfigItem.new(key: :link,
                                       description: "A link to append to the notify",
                                       is_string: true,
                                       optional: true),
          FastlaneCore::ConfigItem.new(key: :username,
                                       description: "Sender's username of the notify",
                                       is_string: true,
                                       optional: true)
        ]
      end

      def self.output
        # Define the shared values you are going to provide
        # Example
        [
          ['LARK_BOT_DEBUG_INFO', 'A description of what this value contains']
        ]
      end

      def self.authors
        # So no one will ever forget your contribution to fastlane :) You are awesome btw!
        ["lvdaqian@bytedance.com"]
      end

      def self.is_supported?(platform)
        true
      end
    end
  end
end