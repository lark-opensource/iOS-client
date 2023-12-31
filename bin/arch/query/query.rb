# frozen_string_literal: true

require 'csv'
require 'set'
require 'ostruct'
require 'json'
require 'yaml'
require 'colored2'

# Graph Wrapper For Query information and export data
# Online API document: https://bytedance.feishu.cn/docx/H7jHd01lHoJmaSxlAMhcdPz6nrb
class Query
  require_relative './query_pod'
  require_relative './vertex'
  require_relative './edge'
  require_relative './result_wrapper'
  require_relative './report'
  # require_relative './group.rb'
  require_relative './misc'

  # TODO: 关联依赖和App依赖的查询能力. 但是关联依赖会直接导致环的存在，而且增加了依赖的类型区分

  # TODO: 分组graph。但是分组后可能有互相依赖。用DependencyGraph会有冲突..

  # 另外分组的递归依赖(组包含了多余的依赖)不一定真的是自己组的依赖，需要看成员递归依赖再重新分组..
  def inspect
    "#<#{self.class}:#{object_id}>"
  end

  # @param graph [Molinillo::DependencyGraph] graph不应该有环
  # @param group [Hash<Hash>]
  def initialize(graph, group)
    @graph = graph
    @group = group
  end
  attr_reader :graph, :group

  # @return [Vertex]
  def A(id)
    @_vertex = {} unless defined?(@_vertex)
    id = to_id(id)
    @_vertex[id] ||= Vertex.new(self, id, @group[id])
  end
  alias [] A

  # @return [VertexCollection] a chainable api. use .result to get the final result
  def V(*ids, &block)
    ids = _to_ids(ids, self)
    ids = ids.select(&block) if block
    return VertexCollection.new(self, ids.map { |id| to_id id })
  end

  ########## ID Based API

  # 默认是所有节点的集合，可以使用集合的各种方法比如select来选择节点
  include Enumerable
  # yield each node id. use Query.api to extract information
  # self can be ids Enumerable pass to other api accept ids
  def each
    return enum_for(__method__) unless block_given?
    graph.each { |node| yield node.name }
  end

  # *ids接收任意数量的id，或者直接传入id集合，其他*ids的参数都类似
  # @return [Set] return source id of pass in ids
  def I(*ids)
    _to_ids(ids, self).each_with_object(Set.new) do |id, set|
      set.merge graph.vertices[id].predecessors.map(&:name)
    end
  end
  alias predecessors I

  # @return [Set] return target id of pass in ids
  def O(*ids)
    _to_ids(ids, self).each_with_object(Set.new) do |id, set|
      set.merge graph.vertices[id].successors.map(&:name)
    end
  end
  alias successors O

  # @return [Set<Edge>] return in edges for ids
  def IE(*ids)
    _to_ids(ids, self).each_with_object(Set.new) do |id, set|
      set.merge(graph.vertices[id].predecessors.map { |n| Edge.new(n.name, id) })
    end
  end
  alias in_edges IE

  # @return [Set<Edge>] return out edges for ids
  def OE(*ids)
    _to_ids(ids, self).each_with_object(Set.new) do |id, set|
      set.merge(graph.vertices[id].successors.map { |n| Edge.new(id, n.name) })
    end
  end
  alias out_edges OE
  # @param indirect [Boolean] (experiment) if contains indirect edge
  # @return [Enumerable<Edge>] edges between ids. use to get a subgraph of vertices
  def BE(*ids, indirect: false)
    ids = _to_ids(ids, self).to_set
    if indirect
      a = Set.new
      ids.each do |id|
        oe = OE(id).select { |e| ids.include?(e.target) }
        a.merge(oe) # direct edge

        ro = _recursive_successors_ids(id)
        ro.each do |n|
          next unless ids.include? n
          catch(:has_indirect_path) do
            oe.each do |oe|
              direct = oe.target
              throw(:has_indirect_path) if direct == n or _recursive_successors_ids(direct).include? n
            end
            a.add(Edge.new(id, n, indirect: true)) # add a indirect edge for no other path link
          end
        end
      end
      a
    else
      OE(ids).select { |e| ids.include?(e.target) }
    end
  end
  alias between_edges BE

  # @return [Set] return recursive source id of pass in ids
  def RI(*ids)
    ids = _to_ids(ids)
    case ids.size
    when 0 then I()
    when 1 then Set.new _recursive_predecessors_ids(ids[0])
    else
      ids.each_with_object(Set.new) do |id, set|
        set.merge _recursive_predecessors_ids(id)
      end
    end
  end
  alias recursive_predecessors RI

  # @return [Set] return recursive target id of pass in ids
  def RO(*ids)
    ids = _to_ids(ids)
    case ids.size
    when 0 then O()
    when 1 then Set.new _recursive_successors_ids(ids[0])
    else
      ids.each_with_object(Set.new) do |id, set|
        set.merge _recursive_successors_ids(id)
      end
    end
  end
  alias recursive_successors RO

  # @return [Integer, nil] min length path from source to target
  def min_distance(source, target)
    source, target = to_id(source), to_id(target)
    return 0 if source == target
    return nil unless _recursive_successors_ids(source).include?(target)

    @_min_distance_cache = {} unless defined?(@_min_distance_cache)
    @_min_distance_cache[[source, target]] ||= graph.vertices[target].predecessors.map do |node|
      min_distance(source, node.name)
    end.compact.min + 1
  end

  # @return [Integer, nil] max length path from source to target, or nil if no path
  def max_distance(source, target)
    source, target = to_id(source), to_id(target)
    # recur version
    return 0 if source == target
    return nil unless _recursive_successors_ids(source).include?(target)

    @_max_distance_cache = {} unless defined?(@_max_distance_cache)
    @_max_distance_cache[[source, target]] ||= graph.vertices[target].predecessors.map do |node|
      max_distance(source, node.name)
    end.compact.max + 1
    # TODO: 递归深度优化, 暂时不考虑，因为recursive_successors之类的也没有限制
  end

  # @!parse
  #   # abstract graph method
  #   module Graph
  #    # @return [Vertex] get node by id
  #    def [](id); end
  #    # @return [Enumerable<Edge>] edge dst must == id
  #    def IE(*id); end
  #    # @return [Enumerable<Edge>] edge src must == id
  #    def OE(*id); end
  #    # @return [Enumerable<Edge>] edge src and dst must in ids
  #    def BE(*ids); end
  #   end

  ########## Cache Helper
  def clear_cache
    %i[@_vertex
       @_min_distance_cache
       @_max_distance_cache
       @_recursive_predecessors_ids
       @_recursive_successors_ids
    ].each do |key| # rubocop:disable all
      remove_instance_variable(key) if instance_variable_defined?(key)
    end
  end

  # @return [Set] return recursive source id of arg id
  def _recursive_predecessors_ids(id)
    @_recursive_predecessors_ids = {} unless defined?(@_recursive_predecessors_ids)
    @_recursive_predecessors_ids[id] ||= graph.vertices[id].recursive_predecessors.to_set(&:name).freeze
  end

  # @return [Set] return recursive target id of arg id
  def _recursive_successors_ids(id)
    @_recursive_successors_ids = {} unless defined?(@_recursive_successors_ids)
    @_recursive_successors_ids[id] ||= graph.vertices[id].recursive_successors.to_set(&:name).freeze
  end

  # @return [Array]
  # @sg-ignore
  def _to_ids(ids, backup = nil)
    case ids.size
    when 0
      return backup || ids
    when 1
      ids = ids[0]
      # 如果id也是数组，会被展开从而无效.., 所以id不能是数组
      return [to_id(ids)] unless ids.is_a?(Enumerable)
    end
    return ids.map { |id| to_id id }
  end

  def to_ids(*ids)
    _to_ids(ids)
  end
  def to_id(id)
    if id.respond_to?(:id)
      id.id
    else
      id
    end
  end

  ########## Helper
  def self.include_playground
    require_relative './playground'
    include Playground
  end

  # @return ids with same root as input ids
  def root(*ids)
    to_root = ->(id) { id.split('/', 2).first }
    set = _to_ids(ids, self).to_set { |id| to_root.(id) }
    select { |id| set.include?(to_root.(id)) }
  end

  def show_pod_in(id, out = nil, subspecs: false)
    id = to_id id
    ids = subspecs ? (select { |v| v == id or v.start_with?(id + '/') }) : [id]
    edges = IE(ids).sort_by do |e|
      d = max_distance(e.S, e.T)
      e.dot = "taillabel=#{d.to_s.inspect}"
      d
    end
    gen_digraph edges, out, layout: 'twopi'
  end

  def show_pod_out(id, out = nil, subspecs: false)
    id = to_id id
    ids = subspecs ? (select { |v| v == id or v.start_with?(id + '/') }) : [id]
    edges = OE(ids).sort_by do |e|
      d = max_distance(e.S, e.T)
      e.dot = "headlabel=#{d.to_s.inspect}"
      d
    end
    gen_digraph edges, out, layout: 'twopi'
  end

  # show relations between two endpoint
  # from, to can be set of id, or nil to mean no limit(which may be very slow..)
  def show_path(from, to, out: nil, &filter)
    o = from && RO(from).merge(to_ids(from))
    i = to && RI(to).merge(to_ids(to))
    gen = lambda { |nodes|
      nodes = nodes.select(&filter) if filter
      if nodes.empty?
        puts "empty node set"
        return
      end
      edges = BE(nodes, indirect: filter)
      root_in = edges.each_with_object(Set.new) { |e, a| a << e.S << e.T }
      root_out = root_in.dup
      # @param [Edge]
      edges.each do |edge|
        root_in.delete(edge.T)
        root_out.delete(edge.S)
      end

      node_attr = lambda { |n|
        if root_in.include? n
          { color: 'orange', style: 'filled' }
        elsif root_out.include? n
          { color: 'cyan', style: 'filled' }
        end
      }
      gen_digraph edges, out, node_attr: node_attr
    }
    if o and i
      both = i & o
      gen.(both)
    elsif o
      gen.(o)
    elsif i
      gen.(i)
    else
      puts "`from` and `to` is not set"
    end
  end

  # 当前架构层级和业务分组依赖关系
  # @param group [Symbol, true, nil] if true or :biz, group by biz, else group by layer, unless nil
  def show_arch(out = nil, group: nil)
    id = lambda { |v|
      v = A(v)
      [v.layer, v.biz].join(':')
    }
    nodes = to_a
    if group
      type = group == :biz ? 1 : 0
      group = Tree.group_by(nodes.map(&id).uniq) { |v| v.split(':', 2)[type] }
    end
    edges = OE(nodes).map { |v| Edge.new(id.(v.S), id.(v.T)) }.uniq.reject { |v| v.S == v.T }
    gen_digraph(edges, out, group: group, layout: 'dot')
  end

  # 按bizs和layers过滤包含的组件节点后展示的依赖关系图
  # @param external [Boolean, nil] 是否显示外部依赖分组
  def show_group(bizs: nil, layers: nil, external: nil, out: nil)
    # TODO: 优化生成依赖图的交互能力
    bizs = Array(bizs)
    layers = Array(layers)
    return if bizs.empty? and layers.empty?
    nodes = self.select { |id|
      v = A(id)
      bizs.empty? || bizs.include?(v.biz) and
        layers.empty? || layers.include?(v.layer)
    }.to_set
    edges = if external
              highlight = Set.new
              OE(nodes).map { |v|
                target = if nodes.include?(v.T)
                           A(v.T).root
                         else
                           [A(v.T).layer, A(v.T).biz].join(':').tap { |v| highlight.add v }
                         end
                Edge.new(A(v.S).root, target)
              }.uniq
            else
              BE(nodes).map { |v| Edge.new(A(v.S).root, A(v.T).root) }.uniq
            end
    edges.reject! { |k| k.S == k.T }
    # label太密集不好看
    gen_digraph(edges, out,
                layout: 'dot',
                node_attr: ->(n) { { color: 'orange', style: 'filled' } if highlight&.include? n })
  end

  # rubocop:disable Lint/Debugger
  def repl_pry
    require 'pry'
    binding.pry quiet: true # rubocop:disable all
  end
  def repl_irb
    require 'irb'
    if Gem::Version.new(RUBY_VERSION) >= Gem::Version.new("3.2")
      # @sg-ignore
      binding.irb(show_code: false) # rubocop:disable all
    else
      binding.irb
    end
  end
  # rubocop:enable Lint/Debugger
end
