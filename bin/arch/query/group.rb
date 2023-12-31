# frozen_string_literal: true

class Query
  # TODO: 分组graph。但是分组后可能有互相依赖。用DependencyGraph会有冲突..
  # 另外分组的递归依赖(组包含了多余的依赖)不一定真的是自己组的依赖，需要看成员递归依赖再重新分组..
  # TBD: 还未完全ready，没想好和Enumerable group_by间的关系
  class Group
    attr_reader :ids, :keyfunc

    def inspect
      "#<#{self.class}:#{object_id}>"
    end

    def initialize(parent, ids, keyfunc)
      @parent = parent
      @ids = Set.new(ids) # member ids. edges only between ids and group it
      @keyfunc = keyfunc
      @group = ids.group_by(&@keyfunc)
    end
    include Enumerable
    def each(&block)
      @group.each_key(&block)
    end
    def [](group)
      @group[group]
    end
    # expand to element in group.
    # return all elements in group if group is nil
    def members(id = nil)
      id ? @group[id] : @ids
    end
    # return [Vertex] has property: members
    def A(id)
      Vertex.new(self, id, { members: @group[id] })
    end

    # NOTE: 用array当id会冲突.., 区分不出来是集合还是元素..
    def I(*ids) # group ids
      ids.each_with_object(Set.new) do |id, set|
        set.merge Set.new(@parent.I(*@group[id]).select { |n| @ids.include?(n) }.map(&@keyfunc)).delete(id)
      end
    end
    alias predecessors I
    def O(*ids)
      ids.each_with_object(Set.new) do |id, set|
        set.merge Set.new(@parent.O(*@group[id]).select { |n| @ids.include?(n) }.map(&@keyfunc)).delete(id)
      end
    end
    alias successors O
    def IE(*ids)
      ids.each_with_object(Set.new) do |id, set|
        set.merge(@parent.I(*@group[id]).map { |n|
                    other = @keyfunc.(n)
                    Edge.new(other, id) unless other == id
                  }.compact)
      end
    end
    alias in_edges IE
    def OE(*ids)
      ids.each_with_object(Set.new) do |id, set|
        set.merge(@parent.O(*@group[id]).map { |n|
                    other = @keyfunc.(n)
                    Edge.new(id, other) unless other == id
                  }.compact)
      end
    end
    alias out_edges OE
    def group_by(ids, &block)
      return enum_for(__method__, ids) unless block
      return Group.new(self, ids, block)
    end
  end
end
