# frozen_string_literal: true

RSpec.describe Query do
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
    described_class.new(graph, {})
  }
  it 'can enum all nodes' do
    expect(subject.to_a).to eq(%w[AA BB CC DD])
    expect(subject.each.to_a).to include(*%w[AA BB CC DD])
  end
  it 'can query deps' do
    expect(subject.O('AA')).to contain_exactly('BB', 'CC', 'DD')
    expect(subject.I('BB', 'CC')).to contain_exactly('AA')
    expect(subject.IE(['BB'])).to contain_exactly(Query::Edge.new('AA', 'BB'))
    expect(subject.OE(['AA'])).to contain_exactly(Query::Edge.new('AA', 'BB'),
                                                  Query::Edge.new('AA', 'CC'),
                                                  Query::Edge.new('AA', 'DD'))
    expect(subject.BE('AA', 'BB')).to contain_exactly(Query::Edge.new('AA', 'BB'))

    expect(subject.RI('DD')).to contain_exactly('AA', 'CC')
    expect(subject.RI('DD', 'BB')).to contain_exactly('AA', 'CC')
    expect(subject.RI()).to contain_exactly('AA', 'CC')
    expect(subject.RO('AA')).to contain_exactly('BB', 'CC', 'DD')
    expect(subject.RO('BB', 'CC')).to contain_exactly('DD')
    expect(subject.RO()).to contain_exactly('BB', 'CC', 'DD')
  end

  it 'can calculate distance for nodes' do
    expect(subject.min_distance('AA', 'DD')).to eq(1)
    expect(subject.min_distance('BB', 'DD')).to eq(nil)
    expect(subject.min_distance('BB', 'BB')).to eq(0)

    expect(subject.max_distance('AA', 'DD')).to eq(2)
    expect(subject.max_distance('BB', 'DD')).to eq(nil)
    expect(subject.max_distance('BB', 'BB')).to eq(0)
  end
end
