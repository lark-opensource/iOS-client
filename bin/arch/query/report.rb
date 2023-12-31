# frozen_string_literal: true

class Query
  # @return [String, nil] 自定义digraph样式定义，插入生成的digraph中
  attr_accessor :digraph_style
  # 输出dot语法依赖文件
  # @param group [Tree<Enumerable<id>>, nil] 节点分组信息, 也可以用来显示没有边的节点
  # @param edge_attr ^(e) -> Hash 获取edge属性的Proc
  # @param node_attr ^(n) -> Hash 获取node属性的Proc
  # @param gen 是否生成图片
  # @param view 是否打开图片
  # @param type 生成图片的格式
  # @param layout 使用的布局方式
  def gen_digraph(edges, output = nil, group: nil, edge_attr: nil, node_attr: nil, gen: true, view: true, type: 'pdf', layout: 'dot', custom: '') # rubocop:disable all
    if output.nil?
      require 'tempfile'
      should_unlink = gen || view
      dot_io = Tempfile.create('digraph')
      output = dot_io.path
    else
      dot_io = File.open(output, 'w')
    end

    ### generate edges
    attr_e = lambda do |e|
      attrs = []
      attrs.push "weight=#{e.weight}" if e.weight
      attrs.push e.dot if e.dot
      if edge_attr and a = edge_attr.(e)
        a.each do |k, v|
          attrs.push "#{k}=#{v.to_json}"
        end
      end
      return if attrs.empty?
      " [#{attrs.join(', ')}]"
    end
    edges_str = edges.map { |e|
      %(  "#{e.source}" -> "#{e.target}"#{attr_e.(e)};)
    }.join("\n")

    ### generate nodes
    if node_attr
      handled_node = Set.new
      attr_n = lambda do |n|
        return unless handled_node.add?(n.to_s)
        return unless a = node_attr.(n) and !a.empty?
        a = a.map do |k, v|
          "#{k}=#{v.to_json}"
        end.join(', ')
        " [#{a}]"
      end
    end
    nodes = H.group_to_digraph(group, &attr_n) if group
    if attr_n
      nodes ||= +''
      add_attr = ->(n) { a = attr_n.(n) and nodes.concat '  ', %("#{n}"), a, ";\n" }
      edges.each do |e|
        add_attr.(e.source)
        add_attr.(e.target)
      end
    end

    ### write syntax file
    # puts "digraph_style", digraph_style
    dot_io.write <<~DI
      digraph Lark {
        overlap=false;
        nodesep=0;
        edge [color="#FF880066"];

      #{digraph_style}
      #{custom}
      #{nodes}
      #{edges_str}
      }
    DI
    dot_io.close
    return output unless gen || view

    ### generate image and may view
    view_path = output + '.' + type
    cmd = %(#{layout} "#{output}" -T#{type} > "#{view_path}")
    puts cmd
    system cmd or raise
    system "open #{view_path}" if view
    view_path
  ensure
    if should_unlink
      File.unlink dot_io.path
      # File.unlink view_path if view_path
    end
  end

  # 输出gephi支持的边文件和节点文件. 会自动给output加相应的后缀
  def gen_gephi_csv(edges, output)
    csv = CSV.generate do |csv|
      csv << %w[Source Target Type Id Label Weight]
      edges.each_with_index do |relation, i|
        csv << [relation.source, relation.target, 'Directed', i, '', 1]
      end
    end
    edge_output = output + '.edges.csv'
    File.write(edge_output, csv)

    ids = Set.new
    edges.each do |relation|
      ids.add(relation.source)
      ids.add(relation.target)
    end
    csv = CSV.generate do |csv|
      csv << %w[Id Label layer biz]
      ids.each do |id|
        csv << [id, id, group.dig(id, 'layer'), group.dig(id, 'biz')]
      end
    end
    node_output = output + '.nodes.csv'
    File.write(node_output, csv)
  end

  # output all data as n-quads format. can be imported by cayley
  def gen_nq(output)
    # https://cayley.gitbook.io/cayley/getting-involved/glossary
    # https://www.w3.org/TR/n-quads/#n-quads-language  for cayley
    nquads = []
    graph.each do |node|
      attrs = group[node.name]
      nquads << "</pod/#{node.name}> <name> #{node.name.dump} ."
      attrs.each do |k, v|
        nquads << "</pod/#{node.name}> <attr/#{k}> #{v.dump} ."
      end
      node.successors.each do |dep|
        nquads << "</pod/#{node.name}> <use> </pod/#{dep.name}> ."
      end
    end
    File.write(output + '.nq', nquads.join("\n"))
  end
end
