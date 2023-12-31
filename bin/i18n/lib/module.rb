# frozen_string_literal: true

module I18n
  module Mod
    # @!attribute [r] i18n_dir
    #   @return [String]
    # @!attribute [r] module_name
    #   NOTE: 这个名字不一定和Pod的名字一样，和传给LanguageManager的一样，用于压缩
    #   @return [String, nil, false] false to ignore this module

    # @return [Hash, nil]
    attr_reader :meta

    def strings
      Dir.glob(File.join(i18n_dir, '*.strings{,dict}'))
    end
  end

  module EESCMeta
    # required methods
    # @!method analyze_code
    # @!attribute [r] module_name
    attr_reader :meta

    # @return [IOSI18n::I18nConfiguration]
    def config
      require 'tempfile'
      require 'EEScaffold'

      analyze_code
      configuration_file = Tempfile.new(module_name)
      begin
        # FIXME: meta是否靠谱？合并冲突可能导致手工修改出错。需要对应的检测兼容
        yaml = { module_name => @meta['keys'].keys }
        config = @meta['config'] and yaml['config'] = config
        yaml = yaml.to_yaml
        configuration_file.write(yaml)
        configuration_file.flush
        return IOSI18n::I18nConfiguration.new(configuration_file.path)
      ensure
        configuration_file.close!
      end
    end
  end

  class EESCModule
    include EESCMeta
    include Mod

    # @return [EESCModule, nil]
    def self.create_from_string_path(string_path)
      i18n_dir = File.dirname(string_path)
      code_path = Dir.glob("#{i18n_dir}/../src/*/BundleI18n.swift").first
      unless code_path
        Pod::UI.warn "code_path #{code_path} for i18n #{string_path} not exist!"
        return nil
      end

      return new(i18n_dir, code_path)
    end

    def self.create_from_root(root)
      code_path = Dir.glob(File.join(root, '**/src/*/BundleI18n.swift')).first or return
      string_path = Dir.glob(File.join(root, 'auto_resources/en-US.strings*')).first or return
      return new(File.dirname(string_path), code_path)
    end

    def initialize(i18n_dir, code_path)
      @i18n_dir = i18n_dir
      @code_path = code_path
    end
    attr_reader :i18n_dir, :code_path

    def module_name
      @module_name || (analyze_code && @module_name)
    end

    # @return [Boolean] false if analyze fails
    def analyze_code
      return @module_name unless @module_name.nil?

      require 'json'

      code = File.read(@code_path)
      if (meta = code[/^---Meta---\s*(.*?)^---Meta---/m, 1])
        @meta = JSON.parse(meta)
        @module_name = code[/BundleConfig\.(\w+)AutoBundle/, 1]
        return true
      else
        # TODO: 是否要兼容旧的没有用新版eesc调用接口和提供meta信息的？这个需要改代码，并从其它地方收集信息 #
        # @type [String, Boolean]
        @module_name = false
        return false
      end
    end
  end

  # 小程序那边的Objc Module
  class MicroAppModule
    include EESCMeta
    include Mod
    def self.create_from_root(root)
      Dir.glob(File.join(root, '**/*+i18nGenerated.m')) do |path|
        return new(root, path)
      end
      Dir.glob(File.join(root, '**/*I18n.m')) do |path|
        IO.foreach(path) do |line|
          if (module_name = line[/LanguageHelper getLocaleWith.*moduleName:@"(\w+)"/, 1])
            return new(root, path, module_name: module_name)
          end
        end
      end
      Pod::UI.warn "can't found valid *I18n.m with base call in #{root}"
      return nil
    end

    # @param root [String] pod root dir, caller should ensure valid
    def initialize(root, code_path, module_name: nil)
      @root = root
      @code_path = code_path
      @module_name = module_name
    end
    attr_reader :root, :code_path

    def module_name
      @module_name || (analyze_code && @module_name)
    end

    def i18n_dir
      Dir.glob(File.join(@root, '**/*I18n.bundle'))
    end

    def analyze_code
      return @module_name unless @module_name.nil?

      require 'json'

      code = File.read(@code_path)
      @module_name = code[/LanguageHelper getLocaleWith.*moduleName:@"(\w+)"/, 1] or @module_name = false
      if (meta = code[/^---Meta---\s*(.*?)^---Meta---/m, 1])
        @meta = JSON.parse(meta)
      end
      @module_name
    end
  end
end
