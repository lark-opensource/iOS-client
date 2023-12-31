require 'psych'
require 'find'

Constant_Mapper_Path = "../MailSDK/configurations/i18n/i18n.strings.yaml"
Constant_MailSDK_Path = "../MailSDK"

# 工具方法用于获取path
def colorize(text, color_code)
    colorText = "\e[#{color_code}m#{text}\e[0m"
    puts colorText
end
def getPath(path)
    fullPath = File.expand_path(path, File.dirname(__FILE__))
    fullPath
end

def red(text); colorize(text, 31); end
def yellow(text); colorize(text, 33); end

class I18nData
    def initialize(mapper_path)
        @mapper_path = mapper_path
        parse_mapper_data()
    end

    attr_accessor :text_array
    attr_accessor :use_map
    def parse_mapper_data
        @mapper = Psych.load_file(@mapper_path)
        puts @mapper.keys.count
        @module_name = @mapper.keys[0]
        @text_array = @mapper[@module_name]
        @use_map = Hash.new
        for key in @text_array
            @use_map[key] = false
        end
    end
end

class Scanner
    def initialize(mapper_path, target_dir)
        @mapper_path = mapper_path
        @target_dir = target_dir
        @mapper_data = I18nData.new(@mapper_path)
    end

    def scan_useless_info
        Find.find(@target_dir) do |path|
            if shouldCheck(path)
                check(path)
            end
        end
    end

    def shouldCheck(path)
        if FileTest.directory?(path)
            return false
        end

        if File.extname(path) != ".swift"
            return false
        end

        if File.basename(path, ".swift") == "BundleI18n"
            return false
        end

        return true
    end

    def check(path)
        puts path
        File.open(path,"r"){|f|
            f.each_line.with_index do |line, i|
                for text in @mapper_data.text_array
                    # 这个test已经有了，不用找
                    res = @mapper_data.use_map[text]
                    if res == true
                        next
                    end
                    if line.include? text
                        @mapper_data.use_map[text] = true
                        next
                    end
                end
            end
        }
    end

    def output_result
        red("没使用到的文案如下：")
        @mapper_data.use_map.each do |key,value|
            if value == false
                yellow(key)
            end
        end
    end

    def clean_i18n_yaml
        content = ""
        unuse_texts = Array.new
        @mapper_data.use_map.each do |key,value|
            if value == false
                unuse_texts.push(key)
            end
        end
        File.open(@mapper_path,"r+"){|f|
            f.each_line{|line|
                unuse = false
                for text in unuse_texts
                    if line.include? text
                        unuse = true
                        break
                    end
                end
                if !unuse
                    content += line
                end
            }
        }
        File.open(@mapper_path, 'w') do |f|
            f.write(content)
        end
        red("删除了以下文案：")
        for text in unuse_texts
            red(text)
        end
    end
end

mapper_path = ARGV[0]
if !mapper_path
    mapper_path = getPath(Constant_Mapper_Path)
end
target_dir_path = ARGV[1]
if !target_dir_path
    target_dir_path = getPath(Constant_MailSDK_Path)
end

scan = Scanner.new(mapper_path, target_dir_path)
scan.scan_useless_info()
scan.output_result()
# scan.clean_i18n_yaml()
