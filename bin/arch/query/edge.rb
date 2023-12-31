# frozen_string_literal: true

class Query
  class Edge < OpenStruct
    attr_accessor :source, :target

    def initialize(source, target, **attrs)
      @source, @target = source, target
      super(attrs)
    end

    alias src source
    alias dst target
    alias dest target
    alias S source
    alias T target
    alias D target
    alias src= source=
    alias dst= target=
    alias dest= target=
    alias S= source=
    alias T= target=
    alias D= target=

    # special attr
    # dot: edge attr for dot generate. eg: label="xxx", weight=999

    def hash; [source, target].hash; end
    def ==(other); other.is_a? Edge and other.source == source and other.target == target; end
    alias eql? ==
    def to_s
      "#{src} -> #{dst}"
    end
    def inspect
      detail = @table.map do |key, value|
        "#{key}=#{value.inspect}"
      end.join(',')
      detail = ": [#{detail}]" unless detail.empty?
      "#<#{src} -> #{dst}#{detail}>"
    end
  end
end
