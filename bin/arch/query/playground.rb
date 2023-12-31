# frozen_string_literal: true

class Query
  # myself private playground code
  module Playground
    # @!parse
    #  include Query

    ### candidate API is put at top

    # subgraph by cluster group
    def group_by(ids = nil, &block)
      return enum_for(__method__, ids) unless block
      ids = to_a if ids.nil?
      return Group.new(self, ids, block)
    end

    def puts_sorted_instabilities
      sort_by { |id| -RO(id).size }
        .group_by { |id| A(id).layer }
        .each do |g, ids|
          puts "==> layer #{g}".green
          ids.each do |id|
            instability = A(id).instability
            instability = instability.to_s.red if I(id).any? { |i| A(i).instability < instability }

            i = I(id).size
            o = O(id).size
            puts "#{id.blue}: #{instability} #{i}/#{o}"
          end
        end
    end
    def puts_grouped_sorted_instabilities
      group = group_by(sort_by { |id| -RO(id).size }) { |id| [A(id).layer, A(id).root] }
      group.each.group_by { |g| g[0] }
           .each do |g, ids|
        puts "==> layer #{g}".green
        ids.each do |id|
          instability = group.A(id).instability
          instability = instability.to_s.red if group.I(id).any? { |i| group.A(i).instability < instability }

          i = group.I(id).size
          o = group.O(id).size
          puts "#{id[1].blue}: #{instability} #{i}/#{o}"
        end
      end
    end

    def gen_g6_csv(relations, output)
      # 有点卡... 不如上面的gephi好用..
      csv = CSV.generate do |csv|
        csv << %w[source target relation]
        relations.each_with_index do |relation, _i|
          csv << [relation.from, relation.target, 'Directed']
        end
      end
      edge_output = output + '.edges.csv'
      File.write(edge_output, csv)

      ids = Set.new
      relations.each do |relation|
        ids.add(relation.from)
        ids.add(relation.target)
      end
      csv = CSV.generate do |csv|
        csv << %w[id Label]
        ids.each do |id|
          csv << [id, id]
        end
      end
      node_output = output + '.nodes.csv'
      File.write(node_output, csv)
    end

    def gen_ccm_word_count(relations, output)
      words = Set.new
      source_word_count = Hash.new(0)
      relations.each do |relation|
        source_word_count[relation.from] += 1
        words.add(relation.from)
      end

      target_word_count = Hash.new(0)
      relations.each do |relation|
        target_word_count[relation.target] += 1
        words.add(relation.target)
      end

      csv = CSV.generate(col_sep: "\t") do |csv|
        csv << %w[Name Source Target SourceCount TargetCount]
        words.each do |word|
          csv << [word, ([word] * source_word_count[word]).join(','), ([word] * target_word_count[word]).join(','),
                  source_word_count[word], target_word_count[word]]
        end
      end
      File.write(output, csv)
    end

    ########## Play
    def play_single_pod
      show_pod_out 'MessengerMod', '/tmp/a.dot', subspecs: true
      show_pod_out 'TTVideoEditor', '/tmp/a.dot', subspecs: true
      show_pod_out 'ByteViewMod', '/tmp/a.dot', subspecs: true
      show_pod_in 'LarkAssembler', '/tmp/a.dot', subspecs: true
      show_pod_in 'LarkLocalizations', '/tmp/a.dot', subspecs: true
    end
    def play_cross_layer_edges
      edges = OE().select { |e| A(e.S).layer != A(e.T).layer }.map { |e| Edge.new(A(e.S).root, A(e.T).root) }.uniq
      gen_digraph(edges, '/tmp/cross_layer_edges.dot')

      # 跨层级依赖数
      puts map {
             [A(_1), IE(_1).select { |e|
                       A(e.S).layer != A(e.T).layer
                     }.size]
           }.sort_by { _2 }.map { "#{_1}: i #{_2} ro: #{_1.RO.size}" }
    end
    def play
      each.group_by { |id| A(id).root }
          .select { |_k, v| v.size > 1 }
          .sort_by { |_k, v| I(v).size - v.size }

      gen_gephi_csv(relation_for_nodes, '/tmp/gephi')
      gen_ccm_word_count(relation_for_nodes, '/tmp/ccm.tsv')
      gen_nq('/tmp/cayley')

      gen_digraph OE().map { |v| Edge.new(A(v.S).root, A(v.T).root) }.uniq

      layers = ['platform']
      nodes = V { |id| layers.include?(A(id).layer) }
      edges = nodes.BE.map { |v| Edge.new(A(v.S).root, A(v.T).root) }.uniq
      group = Tree.group_by(nodes) { |v| A(v).biz }.transform_payload! { |c| c && c.map { A(_1).root }.uniq }
      gen_digraph(edges, out, layout: 'dot', group: group, custom: 'newrank=true;')

      bizs = ['messenger']
      layers = []
      nodes = V { |id| bizs.include?(A(id).biz) }
      edges = nodes.BE.map { |v| Edge.new(A(v.S).root, A(v.T).root) }.uniq
      group = Tree.group_by(nodes) { |v| A(v).layer }.transform_payload! { |c| c && c.map { A(_1).root }.uniq }
      gen_digraph(edges, out, layout: 'dot', group: group, custom: 'newrank=true;')

      [
        'messenger',
        'calendar',
        'todo',
        'ccm',
        'mail',
        %w[openplatform workplace],
        %w[passport ug],
        %w[byteview minutes larklive],
        'meego',
        'securitycompliance',
        'lark',
        %w[toutiao ies bytedance],
        'opensource',
        'external'
      ].each { |v| show_group bizs: v, external: 1 }

      # 裁剪掉多余的边，连通性需要靠递归依赖来判断..
      # min_edges = outE(self).filter { |e| max_distance(e.source, e.target) == 1 }
      # out = gen_digraph min_edges, '/tmp/a.dot', group: group_nodes(graph, %w[layer biz])
      # `open #{out}`

      # gen_g6_csv(relation_for_nodes, '/tmp/g6')
      # out = gen_digraph deps_for(['LarkChat'], 2), '/tmp/a.dot'
    end

    ########## Example
  end
end
