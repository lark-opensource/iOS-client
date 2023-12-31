#!/usr/bin/env ruby
# coding: utf-8

class String
  def black;          "\e[30m#{self}\e[0m" end
  def red;            "\e[31m#{self}\e[0m" end
  def green;          "\e[32m#{self}\e[0m" end
  def brown;          "\e[33m#{self}\e[0m" end
  def blue;           "\e[34m#{self}\e[0m" end
  def magenta;        "\e[35m#{self}\e[0m" end
  def cyan;           "\e[36m#{self}\e[0m" end
  def gray;           "\e[37m#{self}\e[0m" end

  def bg_black;       "\e[40m#{self}\e[0m" end
  def bg_red;         "\e[41m#{self}\e[0m" end
  def bg_green;       "\e[42m#{self}\e[0m" end
  def bg_brown;       "\e[43m#{self}\e[0m" end
  def bg_blue;        "\e[44m#{self}\e[0m" end
  def bg_magenta;     "\e[45m#{self}\e[0m" end
  def bg_cyan;        "\e[46m#{self}\e[0m" end
  def bg_gray;        "\e[47m#{self}\e[0m" end

  def bold;           "\e[1m#{self}\e[22m" end
  def italic;         "\e[3m#{self}\e[23m" end
  def underline;      "\e[4m#{self}\e[24m" end
  def blink;          "\e[5m#{self}\e[25m" end
  def reverse_color;  "\e[7m#{self}\e[27m" end
end

width = 1024 * 50
base  = 1024 * 1

target_dir = `echo \`pwd\`/../Build/$JOB_NAME`.strip
commit = `git rev-parse HEAD`.strip
data_path = File.join(target_dir, 'app-size-data.txt')
#dir_size = `du -sk #{target_dir} | awk '{print \$1}'`
dir_size = Integer(`du -sk #{target_dir} | awk '{print $1}'`) # KB
puts "build directory size: #{dir_size/1024.0}MB".green

if File.exist? data_path
  baseline_size = Integer(`cat #{data_path}|sort|head -1|awk '{print $1}'`) + base # 历史最小值+base
  puts "baseline size: #{baseline_size/1024.0}MB".green
  puts "width size: #{width/1024.0}MB".green
  puts "#{commit} 更新size数据..."
  `echo #{dir_size} #{commit} \`date "+%F %H:%m:%S"\` >> #{data_path}`
  if dir_size <= baseline_size
    exit 0
  else
    delta = dir_size - baseline_size
    if delta > width
      puts "Error: 要控制体重啊，怎么猛增 #{delta}KB".red
      exit 0 # for Error
    else
      puts "WARNING: app size delta too large: #{delta}KB".brown
      exit 0 # for Warning
    end
  end
else
  puts "不存在app size文件，新创建...".green
  puts "#{commit} 更新size数据..."
  `echo #{dir_size} #{commit} \`date "+%F %H:%m:%S"\` >> #{data_path}`
  exit 0
end

