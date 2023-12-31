module Fastlane
  module Actions
    class GetSonarIssueAction < Action
      $flag = true
      def self.run(params)
        require 'excon'
        self.getIssue(params,"BUG,VULNERABILITY,SECURITY_HOTSPOT")
        self.getIssue(params,"CODE_SMELL")
        if !$flag
          raise "请处理sonar警告⚠️"
        end
      end

      def self.description
        "send sonar result"
      end

      def self.available_options
        [
            FastlaneCore::ConfigItem.new(key: :sonar_url,
                                       env_name: "SONAR_URL",
                                       description: "url of sonar",
                                       default_value: '',
                                       is_string: true,
                                       optional: false),
            FastlaneCore::ConfigItem.new(key: :assignee,
                                       env_name: "ASSIGNEE",
                                       description: "commit assignee",
                                       default_value: '',
                                       is_string: true,
                                       optional: false),
            FastlaneCore::ConfigItem.new(key: :project_name,
                                        env_name: "SONAR_PROJECT_NAME",
                                        description: "project name of sonar",
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
        ['weiyuning@bytedance.com']
      end

      def self.is_supported?(platform)
        return true
      end

      def self.getIssue(params,types)
        url = "#{params[:sonar_url]}/api/issues/search?componentKeys=#{params[:project_name]}&resolved=false&types=#{types}&createdInLast=1d&assignees=#{params[:assignee]}"
        
        if types == "CODE_SMELL"
            url = url + "&severities=MAJOR,CRITICAL,BLOCKER"
        end
        response = Excon.get(url)
        body = JSON.parse(response.body)
        if body.has_key?("issues")
            for issue in body["issues"]
                begin
                    key = issue["key"]
                    component = issue["component"]
                    message = issue["message"]
                    line = issue["line"]
                    type = issue["type"]
                    assignee = issue["assignee"]
                    if assignee.nil? || assignee.empty?
                        assignee = "unknown"
                    end
                    issueResponse = Excon.get("#{params[:sonar_url]}/api/sources/issue_snippets?issueKey="+key)
                    issueBody = JSON.parse(issueResponse.body)
                    sources = issueBody[component]["sources"]
                    code = ""
                    for codeLine in sources
                        if codeLine["line"] == line
                            code = code + "=> "
                        end
                        code = code + codeLine["line"].to_s + codeLine["code"].gsub(/<span .*?>/,"").gsub(/<\/span>/,"") + "\n"
                    end
                    puts "\n"
                    puts "------------------------------------------------------------------------------------"
                    puts "\033[31m"+ "sonar警告：" + message +"\033[0m\n"
                    puts code
                    puts "------------------------------------------------------------------------------------"
                    $flag = false
                rescue
                    next
                end
            end
        end

      end

    end
  end
end

