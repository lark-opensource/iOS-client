# frozen_string_literal: true

RSpec.describe 'result_wrapper' do
  subject {
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
  it 'can enum all nodes' do
    expect(subject.V.value).to eq(%w[AA BB CC DD])
  end
  it 'can query deps' do
    expect(subject.V('AA').O).to contain_exactly('BB', 'CC', 'DD')
    expect(subject.V('BB', 'CC').I).to contain_exactly('AA')
    expect(subject.V(['BB']).IE).to contain_exactly(Query::Edge.new('AA', 'BB'))
    expect(subject.V(['AA']).OE).to contain_exactly(Query::Edge.new('AA', 'BB'),
                                                    Query::Edge.new('AA', 'CC'),
                                                    Query::Edge.new('AA', 'DD'))
    expect(subject.V('AA', 'BB').BE).to contain_exactly(Query::Edge.new('AA', 'BB'))

    expect(subject.V('DD').RI).to contain_exactly('AA', 'CC')
    expect(subject.V('DD', 'BB').RI).to contain_exactly('AA', 'CC')
    expect(subject.V().RI).to contain_exactly('AA', 'CC')
    expect(subject.V('AA').RO).to contain_exactly('BB', 'CC', 'DD')
    expect(subject.V('BB', 'CC').RO).to contain_exactly('DD')
    expect(subject.V().RO).to contain_exactly('BB', 'CC', 'DD')
  end
end
