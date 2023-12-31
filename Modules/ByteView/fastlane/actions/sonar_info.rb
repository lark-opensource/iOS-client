module Fastlane
  module Actions
    class SonarInfoAction < Action
      def self.run(params)
        require 'excon'
        #发送新BUG信息
        self.sendIssue(params,"BUG,VULNERABILITY,SECURITY_HOTSPOT")
        #查询各项指标的历史
        indexResponse = Excon.post("#{params[:sonar_url]}/api/measures/search_history?component=#{params[:project_name]}&metrics=" + "bugs,code_smells,duplicated_lines_density,coverage,vulnerabilities")
        indexBody = JSON.parse(indexResponse.body)
        status = "OK"
        #和上次比较
        botText = "#{params[:project_name]} result<at user_id=\"all\"></at>\n"
        for item in indexBody["measures"]
            history = item["history"]
            if item["metric"] == "coverage" && history[-1]["value"]<history[-2]["value"]#覆盖率比上次小
                status = "ERROR"
            elsif item["metric"] != "coverage" && history[-1]["value"]>history[-2]["value"]#其他指标比上次大
                status = "ERROR"
            end
            botText = botText + item["metric"] + ": " + history[-1]["value"] + "\n"
        end
        botText = botText + "sonar url: " +params[:sonar_url]
        Excon.post(params[:bot_url],body: {'title' => "sonar status: "+status,'text' => botText}.to_json)

        self.sendIssue(params,"CODE_SMELL")
      end

      def self.description
        "send sonar result"
      end

      def self.available_options
        [
            FastlaneCore::ConfigItem.new(key: :bot_url,
                                       env_name: "SONAR_BOT_URL",
                                       description: "url of bot",
                                       sensitive: true,
                                       default_value: '',
                                       is_string: true,
                                       optional: false),
            FastlaneCore::ConfigItem.new(key: :sonar_url,
                                       env_name: "SONAR_URL",
                                       description: "url of sonar",
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

      def self.sendIssue(params,types)
        issueList = {}
        today = Time.now
        yestoday = today - 1*24*60*60 #新产生的问题
        dayString = yestoday.year.to_s + "-"
        if yestoday.month < 10
            dayString = dayString + "0"
        end
        dayString = dayString + yestoday.month.to_s + "-"
        if yestoday.day < 10
            dayString = dayString + "0"
        end
        dayString = dayString + yestoday.day.to_s
        #查询项目的问题
        url = "#{params[:sonar_url]}/api/issues/search?componentKeys=#{params[:project_name]}&resolved=false&createdAfter=#{dayString}&types=#{types}"
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
                    if issueList.has_key?(assignee)
                        issueList[assignee].push("message: " + message + "\n" + code + "\n")
                    else
                        issueList[assignee] = ["message: " + message + "\n" + code + "\n"]
                    end
                rescue
                    next
                end
            end
        end
        #按照作者发送日志
        issueList.each_key{
            |key|
            list = issueList[key]
            issueTitle = "Issue of #{key}:" +
            issueText = ""
            for item in list
                issueText = issueText + item + "\n"
            end

            if key == "unknown"
                Excon.post(params[:bot_url],body: {'title' => issueTitle,'text' => issueText}.to_json)
            else
                Excon.post("https://cloudapi.bytedance.net/faas/services/tt555128rv576x6d44/invoke/send_sonar",
                                 headers:{'Content-Type' => 'application/json'},
                                 body: {
                                 'email' => key + "@bytedance.com",
                                 'content' => issueText}.to_json)
                Excon.post(params[:bot_url],body: {'title' => issueTitle,'text' => issueText}.to_json)
            end
        }
      end

    end
  end
end

