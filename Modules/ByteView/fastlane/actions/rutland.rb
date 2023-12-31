module Fastlane
    module Actions
      module SharedValues
        RUTLAND_DOWNLOAD_URL = :RUTLAND_DOWNLOAD_URL
      end
  
      class RutlandAction < Action
        RUTLAND_API = "https://admin.bytedance.com/apptest/api/apprelease/"
  
        def self.run(params)
          UI.success('Upload to rutland has been started. This may take some time.')

          response = self.upload_build(params)
  
          case response.status
          when 200...300
            release_id = response.headers['X-AppRelease-ID']
            download_url = "https://ee.bytedance.net/rutland/apps/#{release_id}.html"
            Actions.lane_context[SharedValues::RUTLAND_DOWNLOAD_URL] = download_url
            UI.success("Build successfully uploaded to rutland! download url:#{download_url}")
          else
            UI.user_error!("Error when trying to upload build file to rutland: #{response.body}")
          end
        end
  
        def self.upload_build(params)
          require 'faraday'
          require 'faraday_middleware'
  
          url = RUTLAND_API
          connection = Faraday.new(url) do |builder|
            builder.request(:multipart)
            builder.request(:url_encoded)
            builder.response(:json, content_type: /\bjson$/)
            builder.use(FaradayMiddleware::FollowRedirects)
            builder.adapter(:net_http)
          end
  
          options = {}
          options[:app_file] = Faraday::UploadIO.new(params[:ipa], 'application/octet-stream')
          options[:public] = params[:public]
          options[:push] = params[:push]
          options[:token] = params[:token]
          options[:whats_new] = ""
  
          if params[:employee_id]
            options[:employee_id] = params[:employee_id]
          end

          if params[:token]
            options[:token] = params[:token]
          end

          if params[:whats_new]
            options[:whats_new] = params[:whats_new]
          end

          post_request = connection.post do |req|
            req.body = options
          end
  
          post_request.on_complete do |env|
            yield(env[:status], env[:body], env[:response_headers]) if block_given?
          end
        end
  
        def self.description
          "TBD"
        end
  
        def self.available_options
          [
            FastlaneCore::ConfigItem.new(key: :token,
                                       env_name: "RUTLAND_EMPLOYEE_TOKEN",
                                       description: "the employee token of uploader",
                                       is_string: true,
                                       optional: false),
            FastlaneCore::ConfigItem.new(key: :employee_id,
                                       env_name: "RUTLAND_EMPLOYEE_ID",
                                       description: "the employee id of uploader",
                                       is_string: true,
                                       optional: false),
            FastlaneCore::ConfigItem.new(key: :ipa,
                                       description: "Path to your IPA file",
                                       default_value_dynamic: true,
                                       verify_block: proc do |value|
                                         UI.user_error!("Couldn't find build file at path '#{value}'") unless File.exist?(value)
                                       end),
            FastlaneCore::ConfigItem.new(key: :whats_new,
                                       description: "Release notes",
                                       is_string: true,
                                       optional: true),
            FastlaneCore::ConfigItem.new(key: :push,
                                       description: "push the new ipa to tester",
                                       default_value: false),
            FastlaneCore::ConfigItem.new(key: :public,
                                       description: "public the  download url of ipa",
                                       default_value: false)
          ]
        end
  
        def self.output
          [
            ['RUTLAND_DOWNLOAD_URL', 'The url to download the ipa']
          ]
        end
  
        def self.authors
          ["lvdaqian@bytedance.com"]
        end
  
        def self.is_supported?(platform)
          [:ios].include?(platform)
        end
  
        def self.example_code
          [
            'rutland'
          ]
        end
  
        def self.category
          :beta
        end
      end
    end
  end

