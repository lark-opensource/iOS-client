# frozen_string_literal: true

class Query
  class Result
    # final result of query. element maybe id, edge, etc. decide by the api called
    attr_reader :result
    alias value result
    # @param query [Query]
    def initialize(query, result)
      @query = query
      @result = result
    end
  end
  class CollectionResult < Result
    # @!attribute [r] result
    #   @return [Enumerable]
    include Enumerable
    def each(&block)
      @result.each(&block)
    end

    def +(other)
      self.class.new(@query, Set.new(@result).merge(other))
    end
    alias | +
    alias merge +
    def -(other)
      self.class.new(@query, Set.new(@result).subtract(other))
    end
    alias subtract -
    def &(other)
      self.class.new(@query, Set.new(@result).intersection(other))
    end
    alias intersection &

    def size; @result.size; end
    alias length size
    def count(&block); @result.count(&block); end
  end
  # a wrapper for query result as a collection. so can use chainable API
  class VertexCollection < CollectionResult
    def I
      VertexCollection.new @query, @query.I(*@result)
    end
    def O
      VertexCollection.new @query, @query.O(*@result)
    end
    def RI
      VertexCollection.new @query, @query.RI(*@result)
    end
    def RO
      VertexCollection.new @query, @query.RO(*@result)
    end
    # 现在edges还不支持后续的chain方法，所以直接返回原来的对象
    def IE
      @query.IE(*@result)
    end
    def OE
      @query.OE(*@result)
    end
    def BE(**opts)
      @query.BE(*@result, **opts)
    end
  end
end
