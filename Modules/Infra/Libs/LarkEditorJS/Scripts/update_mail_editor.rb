require_relative './utils'

module MailEditor
    TARGET_PATH = getPath('../Bizs/LarkEditorJS/resources/EditorVendorJS')
    #EDITOR_PATH = getPath('../Bizs/LarkEditorJS/resources-dev/mail-editor')
    #EDITOR_DEV_PUBLICK = getPath('../Bizs/LarkEditorJS/resources-dev/mail-editor/dist/mobile')
    LINE = "--------------"
    class Packager
        def packge_editor(editor_path)
            yarn_log = `yarn --version`
            if yarn_log.include? "command not found"
                yellow("请等待安装yarn")
                brew_log = `brew --version`
                if brew_log.include? "command not found"
                      log = `/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/master/install.sh)"`
                end
                brew_yarn_log = `brew install yarn`
                green("安装yarn完成，准备开始打包mail-editor资源")
            end
            yellow("#{LINE} 打包 editor 完全版白金究极体 #{LINE}")
            puts `
                cd #{editor_path}
                yarn
                yarn mb
            `
        end

        def copy_resource(editor_path)
            dev_publick_path = editor_path + "/dist/mobile"
            yellow("#{LINE} copy editor到工程内 #{LINE}")
            origianl_index_html = dev_publick_path + "/index.html"
            if !File.exist?(origianl_index_html)
                red("mail前端资源本次未更新")
                return false
            end
            `
            cd #{dev_publick_path}
            cp index.html #{TARGET_PATH}
            cd #{TARGET_PATH}
            rm -rf mail_editor_index.html
            mv index.html mail_editor_index.html
            `
            green("#{LINE} mail资源拷贝流程完成 #{LINE}")
            return true
        end
    end
end
