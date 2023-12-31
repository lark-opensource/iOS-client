# frozen_string_literal: true

class Query
  # private helper functions, to avoid method into Query class
  module H
    # @param tree [Tree]
    def self.group_to_digraph(tree, output = +'', indent: '  ')
      tree.children&.each do |key, value|
        output.concat(indent, %(subgraph "cluster_#{key}" {\n),
                      indent, '  ', %(label="#{key}";\n))
        group_to_digraph(value, output, indent: indent + '  ')
        output.concat(indent, "}\n")
      end
      tree.payload&.each do |node|
        output.concat indent, %("#{node}"#{yield node if block_given?}), ";\n"
      end

      output
    end
  end

  class Tree
    attr_accessor :payload
    # @return [Hash<Tree>]
    attr_accessor :children

    def []=(key, value)
      (@children ||= {})[key] = value
    end
    def [](key)
      @children[key] if @children
    end
    def dig(key, *keys)
      v = self[key] or return nil
      keys.reduce(v) { |a, k| a[k] or break nil }
    end
    # @yield (element) -> [path*] tree.dig(path) == group for elements
    # @return [Tree] generate a tree by group
    def self.group_by(elements)
      tree = Tree.new
      elements.each do |element|
        container = Array(yield element).reduce(tree) { |a, e| a[e] ||= Tree.new }
        (container.payload ||= []) << element
      end
      tree
    end

    # transform the payload node and return self
    # @yield payload -> new payload
    # @return [self]
    def transform_payload!
      visit { |node| node.payload = yield node.payload }
    end
    # 遍历所有tree节点（包含子身）
    # @return [self]
    def visit
      return enum_for(__method__) unless block_given?
      # 遍历所有tree节点
      stack = [self]
      until stack.empty?
        node = stack.shift
        yield(node)
        node.children&.each { |_, value| stack << value }
      end
      self
    end
  end
end
