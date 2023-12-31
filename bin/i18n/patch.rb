# frozen_string_literal: true

# 该文件负责拉取i18n的文案，并patch到相应的目录里

require_relative 'lib/module'
require_relative 'config'
require 'yaml'

module I18n
  # 实现了i18n自动更新的两个接口：更新和Patch
  #
  # 更新使用 bundle exec ruby bin/i18n/patch update 命令，对应拉取参数在 STARLING_CONFIG
  #
  # 重复key前面的优先级更高。（可能和原来各仓库的顺序不一样）。
  # 更新下来的资源在ReplaceResources/i18n.mapper.yaml, 推荐patch入库好对比改动，复查问题
  #
  # 开始用自动更新后，以后自动更新就主要在主工程进行，其他模块主要只是加key生成代码
  #
  # patch代码是patch!方法，通过扫描Pods, Libs, Bizs目录下的auto_resource/en-US.strings文件识别需要更新的模块，用上面提前更新的文案进行patch
  # 对应Podfile里加了两个环境变量:
  # I18N_PATCH==1, 启用文案patch
  # I18N_PATCH_UPDATE==1, patch前更新(不推荐，这个更新没入库，可用于打测试包)
  #
  # patch方法是从代码记录的meta注释提取key和参数，并验证参数个数一致，代码兼容。不兼容的会打印出来(搜索skip), 如果启用strict模式会直接抛错。
  class Patch
    PROJECT_ROOT = File.join(__dir__, '../../')
    DEFAULT_MAPPER_PATH = 'ReplaceResources/i18n.mapper.yaml'

    # rubocop:disable all
    STARLING_CONFIG = [
      { "projectId":2207, "namespaceId": [34815] }, # Lark
      { "projectId":2085, "namespaceId": [34083] }, # Calendar
      { "projectId":2094, "namespaceId": [34137] }, # OpenPlatform
      { "projectId":2095, "namespaceId": [34138, 34143] }, # LittleApp
      { "projectId":2103, "namespaceId": [34191] }, # View
      { "projectId":2108, "namespaceId": [34221] }, # Mail
      { "projectId":2113, "namespaceId": [34246, 34251] }, # CreationMobile
      { "projectId":2187, "namespaceId": [34695] }, # Todo
      { "projectId":2268, "namespaceId": [35181] }, # Minutes
      { "projectId":2521, "namespaceId": [38139] }, # Pano
      { "projectId":3545, "namespaceId": [37986] }, # Moments
    ]
    # rubocop:enable all

    attr_reader :root, :mapper_path, :strict
    # @option strict: 是否报错, true是检查到兼容问题会报错. 否则会跳过
    def initialize(root: PROJECT_ROOT, **options)
      require 'EEScaffold'

      @root = root
      @mapper_path = options[:mapper_path] || File.join(PROJECT_ROOT, DEFAULT_MAPPER_PATH)
      @strict = options[:strict]
    end

    # 更新mapper对应的信息
    def update!
      patch_config = EEScaffold::Project.instance.configuration.origin_configurations['starling_patch']['resources']
      EEScaffold::Project.instance.configuration.starling.resources = patch_config
      EEScaffold.UI.info '获取远端i18n数据.....'
      mapper = IOSI18n::I18nMapperFetch.new.fetch
      @data = {
        'ts' => Time.now.to_i,
        'mapper' => mapper
      }.to_yaml
      File.open(@mapper_path, 'w') do |f|
        f.write @data
      end
    end

    def data
      @data ||= YAML.load_file(@mapper_path)
    end

    # 输出本地用到的Keys
    def keys
      Dir.chdir @root do
        data = _modules.map do |m|
          [m.module_name, m.meta['keys'].keys]
        end.to_h
        puts data.to_yaml
      end
    end

    # @return [Array<EESCModule>]
    def _modules
      modules = Dir.glob('{Bizs,Libs,Pods}/**/auto_resources/en-US.strings')
                   .map { |p| EESCModule.create_from_string_path(p) }
                   .compact
      modules.concat(MicroModules.map { |p| MicroAppModule.create_from_root("Pods/#{p}") }.compact)
      modules.select! { |m| m.module_name && m.meta } # prepare and filter invalid module
      modules
    end

    def patch!
      mapper = IOSI18n::TranslationMapper.new(data['mapper'])
      Dir.chdir @root do
        modules = _modules
        Dir.mktmpdir('i18n_patch') do |temp_dir|
          modules.each do |m|
            patch_module(m, mapper, temp_dir)
          rescue Error, EEScaffold::EEScaffoldException => e
            if strict
              raise
            else
              EEScaffold.UI.warn "skip #{m.module_name} by #{e}"
              Pod::UI.warn "skip #{m.module_name} by #{e}"
            end
          end
        end
      end
    end

    # @param m [EESCModule]
    def patch_module(m, mapper, temp_dir)
      return if ts = m.meta['ts'] and pts = data['ts'] and ts > pts # 如果pod的文案更新，使用pod里的

      EEScaffold.UI.info "patch i18n for #{m.module_name}"

      config = m.config
      config.config&.delete('res_dir') # use patch dir, not the generate dir config
      generator = IOSI18n::I18nResourcesGenerator.new(
        m.module_name, # 现在这个名字就用于生成代码用. 虽然首字母大写了，但更新文案没用上应该不影响
        mapper, config,
        Pathname(temp_dir), Pathname(m.code_path),
        generate_code: false,
        generate_config: false,
        is_use_short_key: m.meta['short_key'],
        is_patch: true # 前向兼容用途标记位，暂时没用。
      )
      generator.generate!

      diff_keys generator.instance_variable_get(:@meta_info)['keys'], m.meta['keys']
      FileUtils.mv Dir[File.join temp_dir, '*.strings{,dict}'], m.i18n_dir
    end

    def diff_keys(patch, old)
      if patch.size != old.size
        msg = 'unequal keys'
        keys_in_patch = patch.keys - old.keys
        msg += ", keys in patch: #{keys_in_patch}"
        keys_in_pod = old.keys - patch.keys
        msg += ", keys in pod: #{keys_in_pod}"
        raise Error, msg
      end
      if patch != old
        msg = patch.map do |k, v|
          "#{k}: patch '#{v}' != old '#{old[k]}' " if v != old[k]
        end.compact.join("\n")
        raise Error, "unequal keys for original pod and patch: \n" + msg
      end
    end
  end
  class Error < StandardError
  end
end

begin
  # execute call
  if File.expand_path($PROGRAM_NAME) == File.expand_path(__FILE__)
    def usage
      warn <<~HELP
        #{$PROGRAM_NAME} update # 更新缓存的i18n文案，文案源最好入库方便追查
        #{$PROGRAM_NAME} patch # 用缓存的i18n文案，patch所有模块. 这一步最好在Podfile pre_install里完成
        #{$PROGRAM_NAME} keys # 输出所有可能会patch的key，根据模块分类
      HELP
      exit
    end
    usage if ARGV.empty? or ARGV.reject! { |a| %w[-h --help].include? a }
    case ARGV[0]
    when /^u.*/
      # TODO: may support config path
      I18n::Patch.new.update!
    when /^p/
      I18n::Patch.new.patch!
    when /^k/
      I18n::Patch.new.keys
    else
      usage
    end
  end
ensure
  Pod::UI.print_warnings if defined? Pod
end
