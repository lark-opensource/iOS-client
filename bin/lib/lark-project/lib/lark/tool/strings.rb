# frozen_string_literal: true

require 'json'

# support .strings file, and keep it's order.
# support add, replace, delete. (no insert)
module Lark
  # Strings格式: https://developer.apple.com/library/archive/documentation/Cocoa/Conceptual/LoadingResources/Strings/Strings.html#//apple_ref/doc/uid/10000051i-CH6-SW10
  class Strings
    def self.load(path)
      new(path: path)
    end

    def initialize(path: nil)
      @data = {}
      @counter = 0 # only inc. @data may delete
      @size = 0
      if path and File.exist? path
        File.open(path) do |f|
          pair = /(".+")\s*=\s*(".+")\s*;/
          f.each_line.with_index do |line, i|
            if pair =~ line
              @data[unescape($1)] = [i, unescape($2), line]
              @size += 1
            else
              @data[i] = [i, line]
            end
          end
        end
        @counter = @data.length
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

    def empty?; @size == 0 end

    def length; @size end

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
      JSON.parse(v)
    rescue # recover from parse error by only unescape some translate
      v[1...-1].gsub(/\\[nrbt"'\\]/, {
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
end
