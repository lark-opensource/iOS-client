# 自动完成如下步骤

# eesc module i18n -n MailSDK -v beta
# MailSDK/MailSDK.podspec改版本号
# eesc module publish -n MailSDK --no-lint-project-git --skip-build
# git branch打tag
# ios-client的对应分支改Podfile
# 触发打包
# 打包结果输出到对应的群

require 'net/http'
require 'json'

MailSDKPodSpecPath = './MailSDK.podspec'
LarkMailPodSpecPath = '../LarkMail/LarkMail.podspec'
ResourcePackageServicePath = './Mail/Services/ResourcePackageService/ResourcePackageService.swift'
NameReg_podfile = /(?<=pod ').*?(?=')/

# helper
def colorize(text, color_code)
  colorText = "\e[#{color_code}m#{text}\e[0m"
  puts colorText
end
def red(text); colorize(text, 31); end
def green(text); colorize(text, 32); end
def yellow(text); colorize(text, 33); end

def getPath(path)
  fullPath = File.expand_path(path, File.dirname(__FILE__))
  fullPath
end

# action

def changePodspecVersion(targetVersion)
  content = ""
  File.open(getPath(MailSDKPodSpecPath),"r+"){|f|
    f.each_line{|line|
      if line.include? "s.version          ="
        newVersion ="  s.version          = \"#{targetVersion}\"\n"
        content += newVersion
      else
        content += line
      end
    }
  }
  File.open(getPath(MailSDKPodSpecPath), 'w') do |f|
    f.write(content)
  end
end

def changeLarkMailVersion(targetVersion)
  content = ""
  File.open(getPath(LarkMailPodSpecPath),"r+"){|f|
    f.each_line{|line|
      if line.include? "s.version"
        newVersion ="  s.version = \"#{targetVersion}\"\n"
        content += newVersion
      else
        content += line
      end
    }
  }
  File.open(getPath(LarkMailPodSpecPath), 'w') do |f|
    f.write(content)
  end
end

def inputIsTrue(input)
  return input != nil && input.length != 0 && (input.casecmp("y") == 0 || input.casecmp("true") == 0 || input == "1")
end

def changePodfile(larkPath, targetVersion)
  podfilePath = larkPath + '/Podfile'
  content = ""
  nameReg = NameReg_podfile
  File.open(podfilePath,"r+"){|f|
    f.each_line{|line|
      if line =~ nameReg and line.include? "MailSDK" and not line.include? "#" # 注释忽略
        newVersion = "  pod 'MailSDK', '#{targetVersion}' #:path => '../mail-ios-client/MailSDK', :inhibit_warnings => false \n"
        content += newVersion
      else
        content += line
      end
    }
  }
  File.open(getPath(podfilePath), 'w') do |f|
    f.write(content)
  end
end

# 触发jenkins打包
def triggerJenkins(mailSDKVersion)
  puts '准备修改podfile'
  yellow('请输入lark主工程目录: (默认值是和mail-ios-client同级): ' + getPath("../../ios-client"))
  larkPath = STDIN.gets.chomp()
  if larkPath.length == 0; larkPath = getPath("../../ios-client") end
  yellow('是否自动修改podfile且提交文件？(y/n)[默认y]')
  modify = STDIN.gets.chomp()
  larkCurrentBranch = `
  cd #{larkPath}
  git symbolic-ref --short HEAD
  `
  if modify.length == 0 || inputIsTrue(modify)
    changePodfile(larkPath, mailSDKVersion)
    puts 'lark工程MailSDK版本号修改完成'
    `
    cd #{larkPath}
    git add Podfile
    git commit -m "feat(mail): 修改MailSDK版本号#{mailSDKVersion}"
    git push origin #{larkCurrentBranch}
    `
  else
    # 检查Lark本地版
    larkGitStatus = `
    cd #{larkPath}
    git status
    `
    if larkGitStatus.include? "modified:   Podfile"
      yellow('Lark工程podfile文件有修改未提交，请确认无误后回车进入下一步')
      STDIN.gets.chomp()
    end
  end
  # 触发打包
  yellow("准备触发打包Lark主工程分支#{larkCurrentBranch}，MailSDK版本号:#{mailSDKVersion}")
  puts larkCurrentBranch
  uri = URI('http://cloudapi.bytedance.net/faas/services/ttui3cohmodt2lthms/invoke/JenkinsService')
  http = Net::HTTP.new(uri.host, uri.port)
  req = Net::HTTP::Post.new(uri, 'Content-Type' => 'application/json')
  req["content-type"] = "application/json"
  req.body = {branch: larkCurrentBranch}.to_json  # `to_json` can be used
  response = http.request(req)
  yellow(response.body)
end

# MARK: 发布前的工程状态检查。
class PublishChecker
  def checkVersionIsLegal(version)
    versionReg = /\d+(\.[a-zA-Z0-9\-]+)/
    legal = version=~ versionReg
    return legal
  end

  def checkResourceService
    # 检查accessKey
    accessKeyAvaliable = true
    File.open(getPath(ResourcePackageServicePath),"r+"){|f|
      f.each_line{|line|
        if line.include? "ResourceAccessKey"
          if line.include? "内测" and not line[0, 2] == "//"
            accessKeyAvaliable = false
            red('请注释内测环境gecko')
          end
        end
      }
    }
    return accessKeyAvaliable
  end

  # 检查本地邮件模板提交状态
  def gitStatusCheck
    gitStatus = `cd #{__dir__};git status`
    if gitStatus.include? "modified:   Resources/mail-native-template"
      red("邮件模板commit号有修改，请检查提交邮件模板")
      return false
    end
    return true
  end

  # release 打包时，检查本地邮件模板是否指向对应 release 分支
  def prepareTemplateForRelease()
    # get current branch for MailSDK
    mailSDK_branch = `cd #{__dir__};git branch --show-current`.delete("\n")

    # check if is a release branch
    if mailSDK_branch.start_with?("release/")
      template_path = "#{__dir__}/Resources/mail-native-template"
      green("检查 mail-native-template 是否指向 #{mailSDK_branch} 最新提交")
      # if so, check if template has release branch
      template_all_branches = `cd #{template_path};git fetch;git branch -r`

      # check if tempalte has the same release branch
      if template_all_branches.include? "origin/#{mailSDK_branch}"
        # template has release branch, check if current commit is the same with last commit with release branch
        template_last_release_commit_hash = `cd #{template_path};git ls-remote | grep refs/heads/#{mailSDK_branch}`.split(' ').first.delete("\n")
        tempalte_current_commit_hash = `cd #{template_path};git rev-parse HEAD`.delete("\n")

        if tempalte_current_commit_hash == template_last_release_commit_hash
          gitStatus = `cd #{__dir__};git status`
          # template diff is in staged, commit before publish
          if gitStatus.include? "modified:   Resources/mail-native-template"
            system("cd #{__dir__};git reset HEAD -- .")
            system("cd #{__dir__};git add Resources/mail-native-template;git commit -m \"update template to #{mailSDK_branch}\"")
          end

          green("template 已在最新 release 分支✅")
          return true
        else
          yellow("目前 template 指向与 #{mailSDK_branch} 最新提交不符，准备切换到对应提交并commit")

          system("cd #{__dir__};git reset HEAD -- .")
          system("cd #{template_path};git -c advice.detachedHead=false checkout #{template_last_release_commit_hash};")
          system("cd #{__dir__};git add Resources/mail-native-template;git commit -m \"update template to #{mailSDK_branch}\"")

          green("已更新 template 指向到 #{mailSDK_branch} 最新提交✅")
          return true
        end
      else
        red("mail-native-template repo 找不到对应分支: #{mailSDK_branch}，请创建release分支并push后进行打包❌")
        return false
      end
    else
      green("当前 MailSDK 分支不为release，不需要检查template分支✅")
      return true
    end
  end

  def checkBeforePublish
    value = true
    value = value && prepareTemplateForRelease
    value = value && checkResourceService
    value = value && gitStatusCheck
    return value
  end
end

def autopPublish(inputVersion, inputNeedPack)
  checker = PublishChecker.new
  if not checker.checkBeforePublish
    return
  end

  if inputVersion != nil
    puts "使用版本：#{inputVersion}"
    version = inputVersion
  else
    yellow('版本信息--> 输入希望发布的版本号:')
    version = STDIN.gets.chomp()
  end

  if not checker.checkVersionIsLegal(version)
    red('请按照规范填写版本号')
    return
  end

  if inputNeedPack != nil
    needTrigger = inputNeedPack
    puts "自动触发打包：#{needTrigger}"
  else
    needTrigger = nil
    # yellow('打包完成后是否需要触发打包？(y/n)[默认n]')
    # needTrigger = STDIN.gets.chomp()
  end

  # 更新文案
  # 暂时去除更新文案逻辑，需求开发按需更新。避免打包时更新文案导致编译问题
  # puts '准备更新文案'
  # system 'eesc module i18n -n MailSDK'
  # puts '文案更新完毕'

  # build template 以防 template 提交没有编译
  puts '准备编译template'
  # install node dependencies
  `cd #{__dir__}/Resources/mail-native-template;npm ci`
  # build template
  `cd #{__dir__}/Resources/mail-native-template;npm run build-all;cd #{__dir__}`
  `cd #{__dir__}/Resources/mail-native-template;git add -A;git commit -m "build for publish"`
  puts 'template编译完成✅'

  puts '生成模板.scaffold_ignore文件，避免上传dev包'
  `python3 #{__dir__}/Resources/mail-native-template/generate_ignore.py`
  puts '.scaffold_ignore修改成功✅'

  #  修改MailSDK版本号 及 发布新版本SDK
  changePodspecVersion(version)
  puts "更新版本号完毕-->准备发布版本：#{version}"
  if not system 'eesc module publish -n MailSDK --no-lint-project-git --skip-build'
    red('发布失败')
    return
  end

  # 发布LarkMail组件
  changeLarkMailVersion(version)
  yellow("更新LarkMail版本号完毕-->准备发布版本：#{version}")
  if not system `cd #{__dir__}; eesc module publish -n LarkMail --no-lint-project-git --skip-build`
    red('发布Lark失败')
    return
  end

  # 打tag
  puts "开始打tag: #{version}"
  gitStatus = `cd #{__dir__};git status`
  if gitStatus.include? "modified:   MailSDK.podspec" or gitStatus.include? "modified:   MailSDK/MailSDK.podspec"
    `git add -A`
    `git commit -m "feat: 发布版本#{version}"`
  end
  system "git tag #{version}"
  # get current branch for MailSDK
  mailSDK_branch = `cd #{__dir__};git branch --show-current`.delete("\n")
  if mailSDK_branch.start_with?("release/")
    # push template for release
    `cd #{__dir__}/Resources/mail-native-template;git push origin HEAD:#{mailSDK_branch}`
    # push MailSDK for release
    `cd #{__dir__};git push`
  end
  # 触发打包相关工作
  # if needTrigger.length != 0 && inputIsTrue(needTrigger)
  #   triggerJenkins(version)
  # end

end

# arguments 格式:
# ruby mail_publish_ci.rb -v={版本}  -p={0}
args = Hash[ ARGV.join(' ').scan(/--?([^=\s]+)(?:=(\S+))?/) ]
version = args['v']
needPack = args['p']

if version == nil && needPack == nil
  green("可使用传入 arguments 格式:\nruby mail_publish_ci.rb -v={发布版本号}  -p={是否自动打包, 1 或 0}\n")
end

autopPublish(version, needPack)


