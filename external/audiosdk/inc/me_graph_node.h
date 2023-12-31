//
// Created by
//  ┬┌─┐┌┐┌
//  ││ ││││ Junjie Shi on 2020/5/18.
// └┘└─┘┘└┘ Copyright (c) 2020 ByteDance. All rights reserved.
//

#ifndef MAMMONSDK_ME_GRAPH_NODE_H
#define MAMMONSDK_ME_GRAPH_NODE_H

#include <memory>
#include "me_node.h"
#include "me_sink_node.h"
#include "me_graph.h"

MAMMON_ENGINE_NAMESPACE_BEGIN

class RouteNode : public Node {
public:
    static std::shared_ptr<RouteNode> create() {
        auto n = std::make_shared<RouteNode>();
        //  RouteNode has no inputs, and outputs will maintained by ElasticGraphNode.
        //// n->addInput();
        //// n->addOutput();
        return n;
    }

    RouteNode() : Node() {
    }

    int process(int port, RenderContext& rc) override;

    std::shared_ptr<Node> getSharedPtr() override {
        return shared_from_this();
    }

    void setParent(Node* parent) {
        parent_ = parent;
    }

    Node* parent_;
};

class MAMMON_EXPORT ElasticGraphNode : public Node {
    friend class SpatializerNode;

public:
    static std::shared_ptr<ElasticGraphNode> create(std::shared_ptr<AudioGraph> graph, RouteNode* route_node,
                                                    Node* entry_node) {
        auto n = std::make_shared<ElasticGraphNode>(std::move(graph), route_node, entry_node);
        n->addInput();
        n->addOutput();
        return n;
    }

    explicit ElasticGraphNode(std::shared_ptr<AudioGraph> graph, RouteNode* route_node, Node* entry_node);

    bool init(std::shared_ptr<AudioGraph> graph, RouteNode* route_node, Node* entry_node);

    int process(int port, RenderContext& rc) override;

    bool cleanUp() override;

    void setId(int id) override;

    audiograph::NodeType type() const override {
        return audiograph::NodeType::GraphNode;
    }

    std::shared_ptr<Node> getSharedPtr() override {
        return shared_from_this();
    }

    std::shared_ptr<AudioGraph> getSubGraph();

    bool isValid();

    /*-- override all functions that use inputs_ and outputs_ --*/

    std::shared_ptr<Node> addInput(size_t num_chan = 2) override;

    // TODO: Detect latency of the sub-graph
    size_t getLatency() const override;

    size_t getMaxLatency() const override;

private:
    RouteNode* route_node_;
    Node* entry_node_;
    SinkNode* exit_node_;
    std::shared_ptr<AudioGraph> sub_graph_;
};
MAMMON_ENGINE_NAMESPACE_END
#endif  // MAMMONSDK_ME_GRAPH_NODE_H
