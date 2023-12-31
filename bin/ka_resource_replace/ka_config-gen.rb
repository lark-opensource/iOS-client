#!/usr/bin/env ruby

def self.usage(name, out)
  out.puts <<~HELP
    Usage:
    #{name} <res_dir> <input> <output>
    parse res_dir and generate the old ka config.json file (usage by fastlane)
  HELP
  false
end

exit usage $0, $stderr if ARGV.empty? or ARGV.reject!(&%w[-h --help].method(:include?))
exit usage $0, $stderr if ARGV.length < 2

require 'json'
require 'pathname'

res_dir = Pathname(ARGV[0])
input = Pathname(ARGV[1]).expand_path
output = Pathname(ARGV[2]).expand_path

strings_name = 'meta'
app_name = 'Lark_App_Name'

Dir.chdir(res_dir) do
  # {ee_resource_lang => infoplist_lang}
  CFBundleDisplayName = {} # rubocop:disable all
  regex_match = /"#{app_name}"\s*=\s*("[^"]+");/
  lang_mapper = {
    'zh_CN' => 'zh-Hans',
    'zh_HK' => 'zh-HK',
    'zh_TW' => 'zh-Hant-TW',
    'Base' => 'base'
  }

  Dir["*.lproj/#{strings_name}.strings"].each do |path|
    next unless name = File.read(path)[regex_match, 1]

    name = JSON.parse(name) # unescape

    lproj = path.sub(/\.lproj.*$/, '')
    # NOTE: lproj默认使用2字母的语言前缀, 需要后缀的要在上面显式的配置映射关系
    lproj = lang_mapper.fetch(lproj) { lproj[0, 2] }

    CFBundleDisplayName[lproj] = name
  end
  if !CFBundleDisplayName.empty? && en = CFBundleDisplayName['en']
    unless CFBundleDisplayName['base']
      CFBundleDisplayName['base'] = en # en 做为base默认值
    end
    CFBundleDisplayName['zh-HK'] ||= en # en 做为base默认值
    CFBundleDisplayName['zh-Hant-TW'] ||= en # en做为base默认值
  end

  # KA海外版需要16国语言，对于平台没下发的语言使用base
  ['de', 'id', 'es', 'fr', 'it', 'vi', 'pt', 'ru', 'hi', 'th', 'ko', 'zh-Hans', 'zh_HK', 'zh-Hant-TW', 'ja', 'en'].each { |lang| CFBundleDisplayName[lang] ||= CFBundleDisplayName['base'] }

  # TODO: build setting read #
  content = {
    'info' => {
      'CFBundleDisplayName' => CFBundleDisplayName,
    }.merge(JSON.load(input)),
    'replace' => {
      'info' => CFBundleDisplayName.map { |k, v|
        [k, { (
                case k
                when 'zh-Hans' then '飞书'
                when 'zh-HK', 'zh-Hant-TW' then '飛書'
                else 'Feishu'
                end
              ) => v,
              'Lark' => v
        }]
      }.to_h
    }
  }

  File.write(output, JSON.pretty_generate(content))
end
