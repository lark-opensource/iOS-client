require 'zip'
require_relative './utils'

class ResourcesZipper
    TEMP_PATH = getPath('../Bizs/LarkEditorJS/resources/EditorVendorJS')
    TEMP_FATHER_PATH = getPath('../Bizs/LarkEditorJS/resources')
    TARGET_PATH = getPath("../Bizs/LarkEditorJS/resources/sourceFiles")
    HOIPATCH_TEMP_NAME = "lark_editor_js"
    HOTPATCH_TEMP_PATH = getPath("../Bizs/LarkEditorJS/resources") + "/#{HOIPATCH_TEMP_NAME}"
    # # 使用zip格式：
    # ZIP_NAME = "EditorVendorJS.zip"
    # # 使用7z格式：
    ZIP_NAME = "EditorVendorJS.7z"
    VERSION_PATH = getPath("../Bizs/LarkEditorJS/resources/sourceFiles/EditorVendorJS.version")
    VERSION_REQUEST_REG = /(?<=version:).*/

    def remove_original_ifneeded
        path = TARGET_PATH + "/#{ZIP_NAME}"
        puts path
        if not File::exist?(path)
            return
        end

        File::delete(path)
    end

    def zip_temp_to_target
        path = TARGET_PATH + "/#{ZIP_NAME}"
        # # 使用zip格式：
        # puts `
        # cd #{TEMP_FATHER_PATH}
        # zip -r #{path} EditorVendorJS
        # `

        # # 使用7z格式：-mx?  压缩级别 https://linux.cn/thread-16334-1-1.html
        puts `
        cd #{TEMP_FATHER_PATH}
        ../../../Scripts/bin/7zz a #{path} EditorVendorJS -mx5
        `
    end

    def generate_new_version(version, is_debug = false)
        new_content = ""
        new_version = ""
        new_line = "version:#{version}\n"
        if version == nil
            File.open(VERSION_PATH,"r+"){|f|
                f.each_line{|line|
                    if line =~ VERSION_REQUEST_REG
                        new_line = "version:#{line.match(VERSION_REQUEST_REG)}"
                    end
                }
            }
        end
        new_content = new_line
        if is_debug
            if new_content[new_content.length - 1] != "\n"
                new_content = new_content + "\n"
            end
            new_content = new_content + "debug"
        end
        green("修改version版本至#{new_version}, 是否debug：#{is_debug}")
        File.open(VERSION_PATH, 'w') do |f|
            f.write(new_content)
        end
    end

    def generate_hot_patch_resource
        puts HOTPATCH_TEMP_PATH
        if not File.exist?(HOTPATCH_TEMP_PATH)
            `mkdir #{HOTPATCH_TEMP_PATH}`
        end
        # 拷贝version文件
        `
        cp #{VERSION_PATH} #{HOTPATCH_TEMP_PATH}
        `
        # 拷贝VendorJS文件夹
        `
        cp -r #{TEMP_PATH} #{HOTPATCH_TEMP_PATH}
        `
        # 生成zip包
        zip_name = "lark_editor_js.zip"
        zip_path = TEMP_FATHER_PATH + "/#{zip_name}"
        # 删除原本的zip包
        if File.exist?(zip_path)
            `rm -rf #{zip_path}`
        end
        puts `
        cd #{TEMP_FATHER_PATH}
        zip -r #{zip_path} #{HOIPATCH_TEMP_NAME}
        `
        # 删除temp文件夹
        `
        cd #{TEMP_FATHER_PATH}
        rm -rf #{HOIPATCH_TEMP_NAME}
        `
    end
end