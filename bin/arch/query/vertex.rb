# frozen_string_literal: true

class Query
  class Vertex < OpenStruct
    # Vertex id, 一般是名字
    attr_reader :id

    def hash; id.hash; end
    def ==(other); other.is_a? Vertex and other.id == id; end
    alias eql? ==
    # 这里不能变，一些函数依赖to_s返回唯一标识进行输出和比对
    def to_s; id.to_s; end
    def inspect
      detail = @table.map do |key, value|
        "#{key}=#{value.inspect}"
      end.join(',')
      "#<#{self.class}:#{id} #{detail}>"
    end

    # @param graph [Graph]
    # @param attrs [Hash] custom attrs
    def initialize(graph, id, attrs)
      @graph = graph
      @id = id
      super(attrs)
    end

    # TODO: 区分edge或者node的type
    # @return [Array<Edge<Vertex>>]
    def IE
      @IE ||= @graph.IE(id).map { |v| edgeID2V v }
    end
    # @return [Array<Edge<Vertex>>]
    def OE
      @OE ||= @graph.OE(id).map { |v| edgeID2V v }
    end
    def I
      self.IE.map(&:S)
    end
    def O
      self.OE.map(&:T)
    end
    # @return [Set]
    def RI
      @RI ||= visit(&:I)
    end
    # @return [Set]
    def RO
      @RO ||= visit(&:O)
    end

    # 广度优先遍历
    # @yield (visit_element) visit start and repeat return additional visit element, nil means no additional element
    # @return [Set] element returned by yield_block,
    def visit(start = [self])
      return enum_for(__method__, start) unless block_given?
      set = Set.new
      stack = start
      until stack.empty?
        p = stack.shift
        yield(p)&.each do |n| # 广度优先遍历
          set.add?(n) and stack.push(n)
        end
      end
      set
    end

    ### additional API

    # 返回pod的root id
    def root
      id.split('/', 2).first
    end

    # 不稳定性: out / (in + out)
    # 目前感觉有用性不是很大.., in是影响范围，out才是稳定性.., 而且也有多个指标..
    def instability
      out = OE().size
      return 0 if out == 0
      i = IE().size
      return out.to_f / (i + out)
    end

    private

    def edgeID2V(edge)
      edge = edge.dup
      edge.S = @graph[edge.S]
      edge.T = @graph[edge.T]
      edge
    end
  end
end
