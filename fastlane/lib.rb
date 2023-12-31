# frozen_string_literal: true

# helper method for define some command function and struct

# to_plist conflict between plist and CFPropertyList..
# this class use system plutil to maintain compatibility with system and avoid conflict
require 'json'
module Apple
  module ApplePlist
    # @return [Hash, Array]
    def self.load(path)
      IO.popen(%w[plutil -convert json -o -].push(path.to_s)) do |pipe|
        JSON.parse pipe.read
      end
    end

    def self.save(obj, path)
      json = JSON.generate(obj)
      IO.popen(%w[plutil -convert xml1 - -o].push(path.to_s), 'r+') do |pipe|
        pipe.write json
        pipe.close_write
      end
    end
  end

  # support .strings file, and keep it's order.
  # support add, replace, delete. (no insert)
  class Strings
    def self.load(path)
      new(path: path)
    end

    def initialize(path: nil)
      @data = {}
      @counter = 0 # only inc. @data may delete
      @size = 0
      if path and File.exist? path
        # value may match multiple lines
        pair = /^[\s&&[^\n]]*(".+")\s*=\s*("(?:[^"]|(?<=\\)")*")\s*;.*$/
        f = File.read(path)
        offset = 0
        append_skip_lines = proc do |e|
          if e > offset
            @data[offset] = [offset, f[offset...e]]
            offset = e
          end
        end
        f.scan(pair) do
          b, e = $LAST_MATCH_INFO.offset(0)
          append_skip_lines[b]
          key, value = $1, $2
          @data[unescape(key)] = [b, unescape(value), $& + "\n"]
          @size += 1
          offset = e + 1
        end
        append_skip_lines[f.length]
        @counter = f.length
      end
    end

    # return a strings file
    def dump
      @data.values.sort.map(&:last).join('')
    end

    def write(path)
      File.write(path, dump)
    end

    ########## query and modify
    include Enumerable
    def each
      return to_enum { @size } unless block_given?

      @data.each do |k, v|
        next if v.length != 3

        yield k, v[1]
      end
    end

    def empty?;
      @size == 0
    end

    def length;
      @size
    end

    def [](key)
      @data[key]&.[](1)
    end

    def []=(key, value)
      if (v = @data[key]) # replace
        v[1] = value
        v[2] = "#{escape(key)} = #{escape(value)};\n"
      else # insert
        @data[key] = [@counter, value, "#{escape(key)} = #{escape(value)};\n"]
        @counter += 1
        @size += 1
      end
    end

    # @return [Boolean] return nil if not exist
    def delete(key)
      @data.delete(key).tap { |v| @size -= 1 if v }
    end

    def transform_values!
      return to_enum { @size } unless block_given?

      @data.each do |k, v|
        next unless v.length == 3

        value = yield v[1]
        unless value == v[1]
          v[1] = value
          v[2] = "#{escape(k)} = #{escape(value)};\n"
        end
      end
    end

    ########## helper
    def escape(v)
      JSON.generate(v)
    end

    def unescape(v)
      # strings文件可能使用\Uxxxx的方式，转换为\u的方式兼容
      JSON.parse(v.gsub("\\U", "\\u"))
    rescue
      v[1...-1].gsub(/\\[nt"'b\\]/, {
                       '\\n' => "\n",
                       '\\r' => "\r",
                       '\\b' => "\b",
                       '\\t' => "\t",
                       '\\"' => '"',
                       "\\\'" => "'",
                       '\\\\' => '\\'
                     })
    end
  end

  # class be used to patch infoplist for ka
  class InfoPlistPatch
    class PatchError < StandardError; end
    def initialize(info_path)
      @path = Pathname(info_path)
      # @type [Hash<String => Strings>]
      @i18n = {}
    end

    def info
      @plist ||= ApplePlist.load @path
    end

    # @return [Strings]
    def i18n(lang)
      @i18n[lang] ||= Strings.load(i18n_path(lang))
    end

    def i18n_path(lang)
      File.expand_path("../#{lang}.lproj/InfoPlist.strings", @path)
    end

    # @return [Set]
    def available_lang
      require 'set'
      @available_lang ||= Dir.glob('*.lproj', base: File.expand_path(File.join(@path, '..')))
                             .map { |v| File.basename(v, '.lproj') }
                             .to_set
    end

    # @yieldparam [Strings]
    # @return [Enumerator, void]
    def each_i18n
      return enum_for(:each_i18n) unless block_given?

      available_lang.each do |lang|
        yield i18n(lang)
      end
    end

    # write patch and replace keyword, then save
    # can use base as plist key modify
    # @param patch [Hash] { Info-key => [Hash<lang => value>, value] }
    # @param replace [Hash] { Lang => [(from, to)] } will change all keyword from to for this language
    # @param url_types [Hash] { CFBundleURLSchemes => String, CFBundleURLName => String, CFBundleURLSchemes => [String] }
    def write(patch, replace, url_types)
      # replace keyword
      if replace
        # batch replace pairs, return a new string
        gsub = lambda do |old, pairs|
          n = old.dup
          pairs.each do |from, to|
            n.gsub! from, to
          end
          n
        end
        # inplace replace strings file value
        replace_strings = lambda do |strings, pairs|
          strings.each do |k, v|
            n = gsub.call v, pairs
            strings[k] = n if n != v
          end
        end
        # inplace replace all string node value recursivly
        replace_plist = lambda do |plist, pairs|
          case plist
          when Hash
            plist.each do |_k, v|
              replace_plist.call v, pairs
            end
          when Array
            plist.each do |v|
              replace_plist.call v, pairs
            end
          when String
            n = gsub.call plist, pairs
            plist.replace n
          end
        end

        replace = replace.dup

        pairs = replace.delete('base') or raise PatchError, "base must set in replace, current value is #{replace}"
        replace_strings.call i18n('Base'), pairs if File.exist? i18n_path('Base')
        replace_plist.call info, pairs

        replace.each do |lang, pairs|
          replace_strings.call i18n(lang), pairs if File.exist? i18n_path(lang)
        end
      end

      # patch k-v pair
      patch.each do |k, v|
        case v
        when Hash # i18n config
          # 没有i18n相关的Key, 不视作i18n Config
          unless v.each.any? { |k, v| (k == 'base' || available_lang.include?(k)) and v.is_a?(String) }
            info[k] = v
            next
          end
          v = v.dup
          base = v.delete('base') or raise PatchError, "base must set in patch, current #{k} value is #{v}"
          info[k] = base
          i18n('Base')[k] = base if File.exist? i18n_path('Base')
          # currently only support modify exist localize
          v.each do |lang, v|
            i18n(lang)[k] = v if File.exist? i18n_path(lang)
          end
        else
          info[k] = v
        end
      end

      # CFBundleURLTypes 数据类型是数组，需要根据 CFBundleURLName 去重后独立处理，直接替换会导致覆盖
      if url_types
        url_types_key = 'CFBundleURLTypes'
        url_types_name_key = 'CFBundleURLName'

        old_url_types = info[url_types_key]

        patch_names = url_types.map { |item| item[url_types_name_key] }.compact
        old_url_types.delete_if { |item| patch_names.include?(item[url_types_name_key]) }

        info[url_types_key] = old_url_types + url_types
      end
      save
    end

    def save
      # TODO: replace lazy write #
      if (info = @plist)
        ApplePlist.save info, @path
        @plist = nil
      end
      @i18n.each do |lang, str|
        str.write i18n_path(lang)
      end
    end
  end
end
