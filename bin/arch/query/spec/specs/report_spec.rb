# frozen_string_literal: true

RSpec.describe 'report' do
  subject {
    require 'molinillo'
    graph = Molinillo::DependencyGraph.new
    a = graph.add_vertex('AA', nil)
    b = graph.add_vertex('BB', nil)
    c = graph.add_vertex('CC', nil)
    d = graph.add_vertex('DD', nil)
    e = graph.add_vertex('DD/EE', nil)
    graph.add_edge(a, b, nil)
    graph.add_edge(a, c, nil)
    graph.add_edge(c, d, nil)
    graph.add_edge(a, d, nil)
    graph.add_edge(a, e, nil)
    Query.new(graph, { 'AA' => { 'biz' => 'im' }, 'CC' => { 'biz' => 'im' } })
  }

  it 'can show_group' do
    allow(subject).to receive(:system).and_return(true)
    expect { subject.show_group(bizs: ['im']) }.to_not raise_error
    expect { subject.show_group(bizs: ['im'], external: true) }.to_not raise_error
    expect { subject.show_arch(group: true) }.to_not raise_error
    expect { subject.show_pod_in('DD', subspecs: true) }.to_not raise_error
    expect { subject.show_pod_out('AA') }.to_not raise_error
  end
end
