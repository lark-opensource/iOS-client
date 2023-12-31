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