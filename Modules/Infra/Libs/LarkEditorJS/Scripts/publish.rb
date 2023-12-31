# this script is use for publish LarkEditorJS

# 使用方法

# 1.ruby publish.rb  打7z包
# 2.mail业务：ruby publish.rb mail
#   打包发布mail资源，copy到目标文件夹为 resource/
#   打7z包


# 导入依赖项
require_relative './update_mail_editor'
require_relative './utils'
require_relative './zip_resource'

# LarkEditorJS的podspec文件的路径。
LARKEDITOR_PODSPEC_PATH = "../Bizs/LarkEditorJS/LarkEditorJS.podspec"

# HotpatchHelper.swift的文件的路径
HOTPATCH_HELPER_PATH = "../Bizs/LarkEditorJS/src/HotpatchHelper.swift"

# vendor.js 资源打包脚本的名字 TODO
VENDOR_JS_SH = ''

# mail_资源打包脚本的名字
MAIL_EDITOR_SH = './update_mail_editor.sh'

# 本次发布的版本号所存在的文件，每次发布前可以修改这个文件，就不用在脚本执行一半时去输入版本号
CONFIG_FILE_VERSION_TO_PUBLISH = './.config_version_to_publish.txt'

# 发布后将版本号写入的pod文件的路径
CONFIG_FILE_IOS_CLIENT_POD_FILE = './.config_ios_client_pod_file.txt'
MAIL_EDITOR_PATH_TXT = './mail_editor_path.txt'
EDITOR_COMMIT_ID_PATH = '../Bizs/LarkEditorJS/src/PathHelper.swift'

class Publisher

  # 打包mail的资源
  def packge_mail_resource(editor_path)
    puts '打包mail前端资源'
    packager = MailEditor::Packager.new
    packager.packge_editor(editor_path)
    updated = packager.copy_resource(editor_path)
    green('打包mail前端资源完成')
    return updated
  end

  def zip_resource()
    zipper = ResourcesZipper.new
    zipper.remove_original_ifneeded()
    zipper.zip_temp_to_target()
  end

  def generate_alpha_version

  end
  
  def change_commit_id(editor_path)
    target_commit_id = `
    cd #{editor_path}
    LANG=en_US.UTF-8 git rev-parse HEAD
    `
    target_commit_branch = `
    cd #{editor_path}
    LANG=en_US.UTF-8 git branch --show-current
    `
    content = ""
    File.open(getPath(EDITOR_COMMIT_ID_PATH), "r+").each_line { |line|
        if line.include? "static let mailCommitId: String ="
          new_line = "    static let mailCommitId: String = \"#{target_commit_id.strip}\" // 请勿手动修改此行，脚本自动修改\n"
          content += new_line
        elsif line.include? "static let mailCommitBranch: String ="
          new_line = "    static let mailCommitBranch: String = \"#{target_commit_branch.strip}\" // 请勿手动修改此行，脚本自动修改\n"
          content += new_line
        else
          content += line
        end
    }
    File.open(getPath(EDITOR_COMMIT_ID_PATH), 'w') do |f|
      f.write(content)
    end
  end
    
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

  def change_Hotpatch_version(target_version)
    content = ""
    File.open(getPath(HOTPATCH_HELPER_PATH),"r+"){|f|
      f.each_line{|line|
        if line.include? "private let edtiorJSVersion" and line.include? "LarkEditorJS_Version"
          newVersion = "private let edtiorJSVersion = \"#{target_version}\" // larkEdtiorJS自定义的版本号 LarkEditorJS_Version (请别修改注释，用于脚本识别)\n"
          content += newVersion
        else
          content += line
        end
      }
    }
    File.open(getPath(HOTPATCH_HELPER_PATH), 'w') do |f|
      f.write(content)
    end
  end

  def push_to_gerrit()
    branch = `git symbolic-ref --short -q HEAD`
    `git push origin HEAD:refs/for/#{branch}`
  end
end

def inputIsTrue(input)
  return input.length != 0 && input.casecmp("y") == 0
end

def package_vendor_js()
  podfilePath = larkPath + '/Podfile'
  content = ""
  nameReg = NameReg_podfile
  File.open(podfilePath,"r+"){|f|
    f.each_line{|line|
      if line =~ nameReg and line.include? "MailSDK" and not line.include? "#" # 注释忽略
        newVersion = "  pod 'MailSDK', '#{targetVersion}'\n"
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


# MARK: 发布前的工程状态检查。
class PublishChecker
  def checkVersionIsLegal(version)
    versionReg = /\d+(\.[a-zA-Z0-9\-]+)/
    legal = version=~ versionReg
    return legal
  end

  # 检查本地邮件模板提交状态
  def gitStatusCheck(editor_path)
    gitStatus = `
    cd #{editor_path}
    LANG=en_US.UTF-8 git diff HEAD
    `
    # 检查
    if not gitStatus.empty?
      red("mail editor有修改内容未提交，请提交后再打包")
      return false
    end
    return true
  end

  def checkHotpatchConfig
    # 检查accessKey
    accessKeyAvaliable = true
    File.open(getPath(HOTPATCH_HELPER_PATH),"r+"){|f|
      f.each_line{|line|
        if line.include? "AccessKey" or line.include? "AccessKey_Oversea"
          if line.include? "内测" and not line[0, 2] == "//"
            accessKeyAvaliable = false
            red('请检查HotpatchHelper.swift文件，注释测试环境而打开正式环境AccessKey')
          end
        end
      }
    }
    return accessKeyAvaliable
  end

  def checkBeforePublish(editor_path)
    value = true
    value = value && gitStatusCheck(editor_path)
    return value
  end

end

class VersionMgr
  def read_version_from_file()
    if not File.exist?(getPath(CONFIG_FILE_VERSION_TO_PUBLISH))
      return ""
    end
    content = ""
    File.open(getPath(CONFIG_FILE_VERSION_TO_PUBLISH),"r+"){|f|
      f.each_line{|line|
        if line != nil and not line.strip.empty?
          if !content.empty?
            yellow("#{getPath(CONFIG_FILE_VERSION_TO_PUBLISH)} 中包含多个非空行，本次已忽略。如要通过该文件指定即将发布的版本号，请保证只包含1个非空行")
            return ""
          end
          content = line.strip
        end
      }
    }
    return content
  end

  def read_version_from_chomp()
    yellow('开始修改版本信息-->输入希望发布的版本号:')
    return gets.chomp()
  end

  def get_new_version()
    version = read_version_from_file()
    if version.empty?
      version = read_version_from_chomp()
    end
    return version
  end

  def modify_ios_client_pod_file(version)
    if not File.exist?(getPath(CONFIG_FILE_IOS_CLIENT_POD_FILE))
        yellow("配置#{getPath(CONFIG_FILE_IOS_CLIENT_POD_FILE)}文件即可自动修改 if_pod.rb 文件，本次没配置，跳过自动修改")
        return
    end
    pod_file_path = ""
    File.open(getPath(CONFIG_FILE_IOS_CLIENT_POD_FILE),"r+"){|f|
      f.each_line{|line|
        if line != nil and not line.strip.empty?
          if !pod_file_path.empty?
            yellow("#{getPath(CONFIG_FILE_IOS_CLIENT_POD_FILE)} 中包含多个非空行，本次已忽略。如要通过该文件自动修改 if_pod.rb，请保证只包含1个非空行")
            return ""
          end
          pod_file_path = line.strip
        end
      }
    }
    if pod_file_path.empty?
        return
    end
    all_content = ""
    old_line = ""
    new_line = ""
    versionReg = /if_pod 'LarkEditorJS', '([^']+)'/
    File.open(pod_file_path,"r+"){|f|
      f.each_line{|line|
        if line =~ versionReg and not line.include? "#" # 注释忽略
          old_line = line
          new_line = line.sub(versionReg, "if_pod 'LarkEditorJS', '#{version}'")
          all_content += new_line
        else
          all_content += line
        end
      }
    }
    File.open(pod_file_path, 'w') do |f|
      f.write(all_content)
    end
    if not old_line.empty? and not new_line.empty?
      yellow("已自动修改 #{pod_file_path}:\nold:\n#{old_line}\nnew:\n#{new_line}")
    end
  end
end

def auto_package(editor_path)
  publisher = Publisher.new
  return publisher.packge_mail_resource(editor_path)
end

def get_mail_editor_path
  if not File.exist?(getPath(MAIL_EDITOR_PATH_TXT))
     red("没有配置Mail Editor位置信息，请先创建#{MAIL_EDITOR_PATH_TXT}文件，并填写Mail Editor绝对位置信息")
     return ""
  end
  editor_path = ""
  File.open(getPath(MAIL_EDITOR_PATH_TXT), "r").each_line { |line|
      if not line.strip.empty?
          editor_path = line.strip
          break
      end
  }
  if editor_path.empty?
      red("无法获取Mail Editor位置信息，请检查#{MAIL_EDITOR_PATH_TXT}文件配置")
      return ""
  end
  green("成功获取Mail Editor位置信息: #{editor_path}")
  return editor_path
end

def auto_publish
  checker = PublishChecker.new
  versionMgr = VersionMgr.new
  editor_path = get_mail_editor_path()
  if editor_path.empty?
      return
  end
  is_goon = true
  if not checker.checkBeforePublish(editor_path)
    is_goon = false
  end

  if !is_goon
    return
  end


  publisher = Publisher.new
  updated = auto_package(editor_path)
  if not updated
      return
  end
  publisher.change_commit_id(editor_path)
  yellow("模板打成7z包")
  publisher.zip_resource()

  #publisher.change_podspec_version(version)
  #publisher.change_Hotpatch_version(version)
  # 自动修改 if_pod.rb 文件
  #versionMgr.modify_ios_client_pod_file(version)
end

if ARGV[0] == "mail"
  auto_publish()
else
  yellow("模板打成7z包")
  publisher = Publisher.new
  publisher.zip_resource()
end
