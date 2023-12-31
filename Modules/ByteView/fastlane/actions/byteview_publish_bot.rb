require 'fastlane_core/print_table'
module Fastlane
  module Actions
    class ByteviewPublishBotAction < Action
      def self.notify(params)
        # fastlane will take care of reading in the parameter and fetching the environment variable:
        require 'faraday'
        require 'faraday_middleware'

        url = params[:url]

        if !url
          print("url is nil")
          return
        end

        connection = Faraday.new(url) do |builder|
          builder.request(:json)
          builder.response(:json, content_type: /\bjson$/)
          builder.use(FaradayMiddleware::FollowRedirects)
          builder.adapter(:net_http)
        end

        options = {}

        options[:is_succeed] = params[:is_succeed]
        options[:open_id] = params[:open_id]
        options[:open_chat_id] = params[:open_chat_id]
        options[:open_message_id] = params[:open_message_id]
        options[:tag_name] = params[:tag_name]
        options[:argv] = params[:argv]

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
          FastlaneCore::ConfigItem.new(key: :is_succeed,
                                       description: "Package succeed or failed",
                                       default_value: true,
                                       is_string: false,
                                       optional: false),
          FastlaneCore::ConfigItem.new(key: :url,
                                       env_name: "LARK_NOTIFY_URL",
                                       description: "The url of Lark notify bot", # a short description of this parameter
                                       is_string: true,
                                       verify_block: proc do |value|
                                          UI.user_error!("No Lark notify bot url given, pass using `url: 'url'`") unless (value and not value.empty?)
                                       end),
          FastlaneCore::ConfigItem.new(key: :argv,
                                       env_name: "LARK_ARGV",
                                       description: "The params Lark notify bot", # a short description of this parameter
                                       is_string: true,
                                       optional: false),
          FastlaneCore::ConfigItem.new(key: :tag_name,
                                       env_name: "TAG_NAME",
                                       description: "tag name",
                                       is_string: true,
                                       optional: false),
          FastlaneCore::ConfigItem.new(key: :open_id,
                                       env_name: "LARK_OPEN_ID",
                                       description: "lark open id",
                                       is_string: true,
                                       optional: true),
          FastlaneCore::ConfigItem.new(key: :open_chat_id,
                                       env_name: "LARK_OPEN_CHAT_ID",
                                       description: "lark open chat id",
                                       is_string: true,
                                       optional: true),
          FastlaneCore::ConfigItem.new(key: :open_message_id,
                                       env_name: "LARK_OPEN_MESSAGE_ID",
                                       description: "lark open message id",
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
        ["ruanmingzhe@bytedance.com"]
      end

      def self.is_supported?(platform)
        true
      end
    end
  end
end
