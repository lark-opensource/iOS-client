# frozen_string_literal: true

RSpec.describe Query::Vertex do
  let(:query) {
    require 'molinillo'
    graph = Molinillo::DependencyGraph.new
    a = graph.add_vertex('AA', nil)
    b = graph.add_vertex('BB', nil)
    c = graph.add_vertex('CC', nil)
    d = graph.add_vertex('DD', nil)
    graph.add_edge(a, b, nil)
    graph.add_edge(a, c, nil)
    graph.add_edge(c, d, nil)
    graph.add_edge(a, d, nil)
    Query.new(graph, {})
  }
  it 'can query vertex deps' do
    n = query.method(:A)
    expect(query.A('AA').O).to contain_exactly(n['BB'], n['CC'], n['DD'])
    expect(query.A('BB').I).to contain_exactly(n['AA'])
    expect(query.A('BB').IE).to contain_exactly(Query::Edge.new(n['AA'], n['BB']))
    expect(query.A('AA').OE).to contain_exactly(Query::Edge.new(n['AA'], n['BB']),
                                                Query::Edge.new(n['AA'], n['CC']),
                                                Query::Edge.new(n['AA'], n['DD']))

    expect(query.A('DD').RI).to contain_exactly(n['AA'], n['CC'])
    expect(query.A('AA').RO).to contain_exactly(n['BB'], n['CC'], n['DD'])
  end
end
