# frozen_string_literal: true

require 'cocoapods'
require 'set'
require_relative 'lib/module'
require_relative 'config'

module I18n
  # 本脚本负责提取多余的语言，并把需要动态下发的语言存到指定目录，以便后续好上传资源包到服务器
  # NOTE: Extension的不裁剪，需要除外

  # 可以根据auto_resources/en-US.strings来提取资源包，判断模块目录
  # 例外特殊处理的一些资源

  # ObjC生成的
  # Pods/EEMicroAppSDK/EEMicroAppSDK/Assets/EMAI18n.bundle/en-US.strings
  # Pods/Timor/Timor/Resources/BDPI18n.bundle/en-US.strings

  # Docs那边的，暂时格式不统一
  # Pods/SKCommon/Scripts/i18n/bitable/main/en-US.strings
  # Pods/SKCommon/Scripts/i18n/docs/i18nCache/en-US.strings

  # Extension用到的
  # Libs/LarkShareExtension
  # Pods/ByteViewBoardcastExtension
  # LarkExtensionCommon

  # strip unused strings file, or compress, on-demand download for save disk size
  # NOTE: this script modify Pods sandbox base on the original contents.
  # should clear to redownload for correct get resources

  class StripLangs
    ExceptionModules = Set['LarkShareExtension', 'ByteViewBoardcastExtension', 'NotificationContentExtension', 'LarkExtensionCommon', 'LarkWidget', 'LarkNotificationContentExtension', 'LarkNotificationContentExtensionSDK', 'LarkTimeFormatUtils']

    XcodeprojTargets = %w[Lark ShareExtension BroadcastUploadExtension NotificationServiceExtension].freeze
    # NOTE: 外部使用需要注意这个文件夹的清理，以及Pods目录的清理(因为修改不会被重新下载)
    # 目前是upload_langs，以及zip会用到这个文件夹
    ResourcesDir = 'Pods/.Gecko'

    # a standard eesc module, which store strings in auto_resources, and have a BundleI18n.swift file
    # @param strategies [Array<Symbol>]
    #   :strip => 只保留KeepLanguages中英日
    #   :meta => 记录模块i18n的meta信息，提供给Runtime
    #   :compress => 压缩调用基类的模块，之后会清理掉资源
    #   WIP: :download => 记录要调用基类方法的模块，之后会上传Gecko. 记录后会清理掉除内置以外的语言
    # @param installer [Pod::Installer] optional installer infomation, if called from pod install
    def initialize(root, strategies, installer: nil)
      @strategies = strategies
      @root = root
      @installer = installer
    end
    attr_reader :root, :strategies, :installer
    
    @KeepLanguages
    def keep_languages
        if @KeepLanguages == nil
            lark_setting_dir = 'Modules/Infra/Libs/LarkSetting/Resources/'
            lark_setting_url = lark_setting_dir + 'lark_settings'
            json = File.read(lark_setting_url)
            obj = JSON.parse(json)
            lang_str = obj["client_build_language_config"]["client_build_language_list"]
            @KeepLanguages = lang_str.split(',').to_set
        end
        return @KeepLanguages
    end

    def resource_dir
      File.join(@root, ResourcesDir)
    end

    # @return [Array] a list of files already save in resource_dir
    def keep_files
      @keep_files ||= begin
        # should call in @root dir

        modules = installer ? modules_from_installer(installer) : modules_from_convention_path
        # @param m [Mod]
        modules.each_with_object([]) do |m, filelist|
          filelist.concat m.strings if m.keep(resource_dir)
        end
      end
    end

    def run!
      Dir.chdir @root do
        strategies.each do |strategy|
          case strategy
          when :strip then strip!
          when :meta then save_meta!
          when :compress, :download
            save_dynmaic_lang!(strategy)
          else
            raise "unsupported strategy #{strategy}"
          end
        end
      end
    end

    # FIXME: 多次调用的话，保存和清理应该怎么弄？
    # 暂定让外部控制，这里只覆盖。
    # 这样的话上层需要控制Pods和资源目录的清理
    def save_dynmaic_lang!(strategy)
      file_to_delete = keep_files

      # compress压缩所有文件，所以不keep，全放到压缩包里. download需要保留核心
      file_to_delete.reject! { |v| will_keep_string(v) } unless strategy == :compress

      # after keep, clean the resources
      return if file_to_delete.empty?

      # generate zip before clean
      zip if strategy == :compress

      Pod::UI.titled_section 'zip and delete dynamic languages:' do
        file_to_delete.each { |p| Pod::UI.info "- #{p}" }
        FileUtils.rm file_to_delete
      end
      true
      # TODO: special dir handle #
    end

    # 压缩资源包并在Xcode里添加引用
    def zip
      Dir.chdir(resource_dir) do
        # <Module>/xx-xx.strings{,dict}
        names = Dir.glob('*/*.strings*').map { |path| File.basename(path, '.*') }.uniq
        # TODO: 黑白名单控制？用英文兜底，不需要base #
        names.delete('LocalizableBase')
        names.each do |name|
          # 资源包为<module>.bundle/<Lang>.strings
          cmd = %(zip -q "#{name}.zip" *.bundle/#{name}.strings*)
          raise "zip failed: #{cmd}" unless system(cmd)
        end
      end
    end

    def save_meta!
      keep_files # trigger meta collect
      return unless Dir.exist? resource_dir

      Dir.chdir(resource_dir) do
        Dir.mkdir('meta') unless Dir.exist? 'meta'
        Dir.glob('*/meta.json').each do |path|
          name = File.basename(File.dirname(path), '.*')
          FileUtils.cp(path, "meta/#{name}.json")
        end
      end
    end

    def strip!
      return unless strip_strings!

      clean_xcodeproj_ref!
    end

    def will_keep_string(path)
      name = File.basename(path, '.*')
      keep_languages.include? name
    end

    def strip_strings!
      will_keep = method(:will_keep_string)
      # @type [Array]
      file_to_delete = Dir.glob('**/auto_resources/*.strings{,dict}').reject(&will_keep)

      # TODO: 小程序14国资源需要特殊删除一下,后续需要统一处理
      file_to_delete.concat(Dir.glob('**/EEMicroAppSDK/**/EMAI18n.bundle/*.strings{,dict}').reject(&will_keep))
      file_to_delete.concat(Dir.glob('**/Timor/**/BDPI18n.bundle/*.strings{,dict}').reject(&will_keep))

      keep_languages_lproj = keep_languages.map { |v| v[0, 2] }.to_set
      file_to_delete.concat(Dir.glob('*/*.lproj/InfoPlist.strings').reject do |path|
        name = Pathname(path).parent.basename('.*').to_s
        next true if name.length == 4 # keep base.lproj

        keep_languages_lproj.include? name[0, 2]
      end)

      return if file_to_delete.empty?

      Pod::UI.titled_section 'strip unneeded languages:' do
        file_to_delete.each { |p| Pod::UI.info "- #{p}" }
        FileUtils.rm file_to_delete
      end
      true
    end

    def clean_xcodeproj_ref!
      # fix SupportedLanguage and xcode file ref
      require_relative '../../fastlane/lib'
      require 'xcodeproj'
      project = $lark_project || Xcodeproj::Project.open(File.expand_path('Lark.xcodeproj'))
      keep_languages_underline = keep_languages.map { |v| v.tr('-', '_') }
      XcodeprojTargets.each do |name|
        # insert SupportedLanguages
        info_path = "#{name}/Info.plist"
        plist = Apple::ApplePlist.load(info_path)
        supported = plist['SUPPORTED_LANGUAGES'].map { |v| v.tr('-', '_') }
        plist['SUPPORTED_LANGUAGES'] = keep_languages_underline & supported
        Apple::ApplePlist.save(plist, info_path)

        # remove deleted infoplist from xcodeproj
        # @type [Xcodeproj::Project::Object::PBXNativeTarget]
        infoplist = project[name].recursive_children.find do |g|
          g.is_a? Xcodeproj::Project::Object::PBXVariantGroup and g.name == 'InfoPlist.strings'
        end
        next unless infoplist

        # @param [Xcodeproj::Project::Object::PBXFileReference]
        infoplist.children.to_a.each do |child|
          child.remove_from_project unless child.real_path.exist?
        end
      end
      project.save if project.dirty?
    end

    private

    def modules_from_convention_path
      # save to convention directory for later upload
      # @type [Array<EESCModule>]
      modules = Dir.glob('{Bizs,Libs,Pods}/**/auto_resources/en-US.strings')
                   .map { |p| EESCModule.create_from_string_path(p) }
                   .compact
      modules.concat(MicroModules.map { |p| MicroAppModule.create_from_root("Pods/#{p}") }.compact)
      return modules
    end

    # @param installer [Pod::Installer]
    def modules_from_installer(installer)
      micro = MicroModules.to_set
      return installer.pod_targets.map do |pt|
        pt.sandbox.pod_dir(pt.root_spec.name)
      end.uniq.map do |root|
        if micro.include? File.basename(root)
          MicroAppModule.create_from_root(root)
        else
          EESCModule.create_from_root(root)
        end
      end.compact
    end
  end

  module Mod
    # generate module infomation for later upload
    # write XXX.bundle in root, which include XXX.strings and meta.json in it
    # @return true if success keep resource in root
    def keep(root)
      return false unless (m = module_name)
      return false if (s = strings).empty?
      return false if StripLangs::ExceptionModules.include? m

      root = Pathname(root).join("#{m}.bundle")
      resources = root
      resources.mkpath

      s.each do |string|
        FileUtils.cp string, resources, preserve: true
      end
      if (meta = self.meta)
        File.open(root + 'meta.json', 'wb') do |file|
          file.write(JSON.generate(meta))
        end
      end

      true
    end
  end
end
