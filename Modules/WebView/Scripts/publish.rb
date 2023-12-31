# this script is use for publish LarkWebViewNativeComponent

# 自动完成如下步骤

# 输入发布的版本号。
# eesc module publish -n LarkWebViewNativeComponent --no-lint-project-git --skip-build
# 自动打tag
# 如果非release分支并且远端存在，会直接push

# 导入依赖项
require_relative './utils'

# LarkEditorJS的podspec文件的路径。
LARKEDITOR_PODSPEC_PATH = "../Bizs/LarkWebviewNativeComponent/LarkWebviewNativeComponent.podspec"

class Publisher
  def change_podspec_version(target_version)
    content = ""
    File.open(getPath(LARKEDITOR_PODSPEC_PATH),"r+"){|f|
      f.each_line{|line|
      if line.include? "s.version          ="
          newVersion ="  s.version          = \"#{target_version}\"\n"
          content += newVersion
      else
          content += line
      end
      }
    }
    File.open(getPath(LARKEDITOR_PODSPEC_PATH), 'w') do |f|
      f.write(content)
    end
  end

  def push_to_remote()
    branch = `git push`
  end
end

def inputIsTrue(input)
  return input.length != 0 && input.casecmp("y") == 0
end


# MARK: 发布前的工程状态检查。
class PublishChecker
  def checkVersionIsLegal(version)
    versionReg = /\d+(\.[a-zA-Z0-9\-]+)/
    legal = version=~ versionReg
    return legal
  end
end

def auto_publish
  checker = PublishChecker.new
  publisher = Publisher.new

  #  修改LarkEditorJS版本号 及 发布新版本SDK
  yellow('开始修改版本信息-->输入希望发布的版本号:')
  version = gets.chomp()
  if not checker.checkVersionIsLegal(version)
    red('请按照规范填写版本号')
    return
  end
  publisher.change_podspec_version(version)
  puts "更新版本号完毕-->准备发布版本：#{version}"
  if not system 'eesc module publish -n LarkWebviewNativeComponent --no-lint-project-git --skip-build'
    red('发布失败')
    return
  end
  # 打tag
  puts "开始打tag: #{version}"
  gitStatus = `
  cd #{getPath("../")}
  git status
  `
  if gitStatus.include? "modified:   LarkWebviewNativeComponent.podspec"
    `git add -A`
    `git commit -m "feat: 发布版本#{version}"`
  end
  system "git tag #{version}"
  branch = `cd #{__dir__};git branch --show-current`.delete("\n")
  if not branch.include? "master"
    # 发起gerrit
    publisher.push_to_remote()
  end
end

auto_publish()