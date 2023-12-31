# frozen_string_literal: true

# to_plist conflict between plist and CFPropertyList..
# this class use system plutil to maintain compatibility with system and avoid conflict
require 'json'
# $CHILD_STATUS need English, see https://github.com/rubocop/rubocop/issues/1747
require 'English'

module Lark
  module Plist
    if /darwin/.match?(RUBY_PLATFORM)
      def self.load(path)
        out = nil
        IO.popen(%w[plutil -convert json -o -].push(path.to_s), 2 => [:child, 1]) do |pipe|
          out = pipe.read
        ensure
          pipe.close_read
        end
        raise ExternalError, out if $CHILD_STATUS != 0

        JSON.parse(out)
      end

      def self.save(obj, path, format = :xml)
        json = JSON.generate(obj)
        format = case format
                 when :xml then 'xml1'
                 when :binary then 'binary1'
                 else raise UnsupportedError, "unknown plsit #{format}"
                 end
        out = nil
        IO.popen(%W[plutil -convert #{format} - -o].push(path.to_s), 'r+', 2 => [:child, 1]) do |pipe|
          pipe.write json
          pipe.close_write # must have or popen not end
          out = pipe.read
        end
        raise ExternalError, out if $CHILD_STATUS != 0
      end
    else
      require 'plist' # 其他平台没有plutil, 使用plist的gem兼容
      def self.load(path)
        ::Plist.parse_xml(path)
      rescue => e
        raise ExternalError, e
      end

      def self.save(obj, path, _format = :xml)
        obj = JSON.parse(JSON.generate(obj)) # plist的兼容性不好
        obj.save_plist(path)
      rescue => e
        raise ExternalError, e
      end
    end
  end
end
