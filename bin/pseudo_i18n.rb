#!/usr/bin/env ruby
# frozen_string_literal: true

require 'pathname'
require_relative '../fastlane/lib.rb'
require 'fileutils'

ACCENTED_MAP = {
  'a' => 'ȧ',
  'A' => 'Ȧ',
  'b' => 'ƀ',
  'B' => 'Ɓ',
  'c' => 'ƈ',
  'C' => 'Ƈ',
  'd' => 'ḓ',
  'D' => 'Ḓ',
  'e' => 'ḗ',
  'E' => 'Ḗ',
  'f' => 'ƒ',
  'F' => 'Ƒ',
  'g' => 'ɠ',
  'G' => 'Ɠ',
  'h' => 'ħ',
  'H' => 'Ħ',
  'i' => 'ī',
  'I' => 'Ī',
  'j' => 'ĵ',
  'J' => 'Ĵ',
  'k' => 'ķ',
  'K' => 'Ķ',
  'l' => 'ŀ',
  'L' => 'Ŀ',
  'm' => 'ḿ',
  'M' => 'Ḿ',
  'n' => 'ƞ',
  'N' => 'Ƞ',
  'o' => 'ǿ',
  'O' => 'Ǿ',
  'p' => 'ƥ',
  'P' => 'Ƥ',
  'q' => 'ɋ',
  'Q' => 'Ɋ',
  'r' => 'ř',
  'R' => 'Ř',
  's' => 'ş',
  'S' => 'Ş',
  't' => 'ŧ',
  'T' => 'Ŧ',
  'v' => 'ṽ',
  'V' => 'Ṽ',
  'u' => 'ŭ',
  'U' => 'Ŭ',
  'w' => 'ẇ',
  'W' => 'Ẇ',
  'x' => 'ẋ',
  'X' => 'Ẋ',
  'y' => 'ẏ',
  'Y' => 'Ẏ',
  'z' => 'ẑ',
  'Z' => 'Ẑ'
}.freeze
ACCENTED_MAP_Values = ACCENTED_MAP.values

SpecialVar = /(\{\{[^}]*\}\}|\{[^}]*\}|%.)/.freeze

# @return [Apple::Strings, nil]
def load_pseudo_strings(path)
  # ignore compiled strings file
  return nil unless File.exist? path
  return nil if File.read(path, 'bplist'.length) == 'bplist'

  strings = Apple::Strings.load(path)
  # @param [String]
  strings.transform_values! do |value|
    # 保留special var, 其它的字符串被替换为*
    value.split(SpecialVar).each_with_object([]) do |s, a|
      if s.start_with?('{', '%')
        a.push s
      else
        s.each_char { |c| a.push ACCENTED_MAP.fetch(c) { ACCENTED_MAP_Values[rand(ACCENTED_MAP.length)] } }
      end
    end.join('')
  end
  return strings
end

def generate_rw(path)
  return unless (strings = load_pseudo_strings(path))

  # NOTE: 这个添加文件还需要在Pods生成xcode引用前，否则资源不会被copy进去..
  strings.write(File.expand_path('../rw.strings', path)) # use ab as pseudo language
end

require 'xcodeproj'
def handle_infoplist
  # @type [Xcodeproj::Project, Object]
  project = $lark_project || Xcodeproj::Project.open(File.expand_path('Lark.xcodeproj'))
  will_support_languages = %w[rw id_ID de_DE en_US es_ES fr_FR it_IT pt_BR vi_VN ru_RU hi_IN th_TH ko_KR zh_CN zh_HK zh_TW ja_JP]
  %w[Lark ShareExtension BroadcastUploadExtension NotificationServiceExtension].each do |name|
    # insert SupportedLanguages
    info_path = "#{name}/Info.plist"
    plist = Apple::ApplePlist.load(info_path)
    supported = plist['SUPPORTED_LANGUAGES']
    # append all localizations
    insert_langs = will_support_languages.reject { |l| supported.include? l }
    unless insert_langs.empty?
      supported.concat(insert_langs)
      Apple::ApplePlist.save(plist, info_path)
    end

    # insert Infoplist.strings
    next unless (strings = load_pseudo_strings(File.expand_path("#{name}/en.lproj/InfoPlist.strings")))

    # @type [Xcodeproj::Project::Object::PBXNativeTarget]
    group = project[name].recursive_children.find do |g|
      g.is_a? Xcodeproj::Project::Object::PBXVariantGroup and g.name == 'InfoPlist.strings'
    end
    insert_langs.each do |insert_lang|
      lang_code = insert_lang[0...2]
      strings_path = File.expand_path("#{name}/#{lang_code}.lproj/InfoPlist.strings")
      next if File.exist? strings_path # skip if already added

      FileUtils.mkdir_p File.dirname strings_path
      strings.write(strings_path)

      if group and !group[lang_code]
        ref = group.new_file(strings_path)
        ref.name = lang_code
      end
    end
  end
  project.save if project.dirty?
end

# collect keys from files and update from rosta
class GenerateStrings
  # @param module_dir [String] dir should contains auto_resources/en-US.strings
  def generate(module_dir, mapper)
    name = File.basename(module_dir)
    return unless configuration = configuration_from_module(module_dir)

    # read strings file
    template_strings = File.join(module_dir, 'auto_resources/en-US.strings')
    return unless File.exist? template_strings

    is_use_short_key = true

    # If short-key enable, length of all keys should be equal to 3;
    keys = Apple::Strings.load(template_strings).map { |k, _v| is_use_short_key &= (k.length == 3) }

    module_dir = Pathname(module_dir)
    auto_resources_base_path = module_dir + 'auto_resources'
    swift_file_path = module_dir + 'src/configurations'
    EEScaffold.UI.info "update i18n for #{name}"
    generator = IOSI18n::I18nResourcesGenerator.new(
      name,
      mapper,
      configuration,
      auto_resources_base_path,
      swift_file_path,
      generate_code: false,
      generate_config: false,
      is_use_short_key: is_use_short_key
    )
    generator.generate!
  end

  # ensure generate language has region
  LANG_MAPPING = {
    'id' => 'id-ID',
    'de' => 'de-DE',
    'en' => 'en-US',
    'es' => 'es-ES',
    'fr' => 'fr-FR',
    'it' => 'it-IT',
    'pt' => 'pt-BR',
    'vi' => 'vi-VN',
    'ru' => 'ru-RU',
    'hi' => 'hi-IN',
    'th' => 'th-TH',
    'ko' => 'ko-KR',
    'zh' => 'zh-CN',
    'ja' => 'ja-JP'
  }.freeze

  # create i18n configuration file, and return it
  # @return [IOSI18n::I18nConfiguration]
  def configuration_from_module(module_dir)
    name = File.basename(module_dir)

    i18n_swift_file = Dir["#{module_dir}/**/BundleI18n.swift"]
    return nil if i18n_swift_file.blank?

    i18n_swift_content = File.open(i18n_swift_file[0]).read

    keys = []
    i18n_swift_content.scan(/^\s+static\s+var\s+([A-Za-z0-9]+\_[\_A-Za-z0-9]+)\s{0,1}:/) { |match| keys.append match.first }
    i18n_swift_content.scan(/^\s+static\s+func\s+([A-Za-z0-9]+\_[\_A-Za-z0-9]+)\(/) { |match| keys.append match.first }

    return nil if keys.empty?

    require 'tempfile'
    configuration_file = Tempfile.new(name)
    begin
      yaml = { name => keys, 'config' => { 'mapping' => LANG_MAPPING } }.to_yaml
      configuration_file.write(yaml)
      configuration_file.flush
      return IOSI18n::I18nConfiguration.new(configuration_file.path)
    ensure
      configuration_file.close!
    end
  end

  def run!
    require 'EEScaffold'
    require 'http' # fix HTTP load issue in current EEScaffold version
    require 'yaml'
    # set the products from rosta
    EEScaffold::Project.instance.configuration.i18nConfigs.parameters.product = %w[
      Lark
      OpenPlatform
      Calendar
      View
      CreationMobile
      Mail
    ]
    EEScaffold.UI.info '获取远端i18n数据.....'
    mapper = IOSI18n::I18nMapperFetch.new('beta').fetch
    # 暂时不缓存, 打包始终获取最新数据
    # cache = '/tmp/mapper.yaml'
    # if File.exist? cache #  and false
    #   mapper = YAML.load_file(cache)
    # else
    #   EEScaffold.UI.info '获取远端i18n数据.....'
    #   mapper = IOSI18n::I18nMapperFetch.new('alpha').fetch
    #   File.open(cache, 'w') do |f|
    #     f.write mapper.to_yaml
    #   end
    # end
    mapper = IOSI18n::TranslationMapper.new(mapper)

    Dir.glob('**/auto_resources/en-US.strings').each do |path|
      generate(File.expand_path('../..', path), mapper)
    end
  end
end

# ensure root is src root
Dir.chdir File.expand_path('..', __dir__) do
  GenerateStrings.new.run!

  puts 'Inject Infoplist'
  handle_infoplist

  puts 'generate rw.strings from all en-US.strings'
  Dir.glob('**/en-US.strings').map { |p| generate_rw(p) }
end
