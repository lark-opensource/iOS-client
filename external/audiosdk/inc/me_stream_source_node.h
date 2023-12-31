//
// Created by chenmanjia on 2020/12/17.
//
#pragma once
#include "mammon_engine_defs.h"
#include "me_source_node.h"
#include "me_node.h"
#include "me_stream_handle.h"

using namespace std;

MAMMON_ENGINE_NAMESPACE_BEGIN

class MAMMON_EXPORT StreamSourceNode : public Node, public SourceNode {
public:
    int process(int port, RenderContext& rc) override;

    std::shared_ptr<Node> getSharedPtr() override {
        return shared_from_this();
    }

    audiograph::NodeType type() const override {
        return audiograph::NodeType::StreamSourceNode;
    }

    static std::shared_ptr<StreamSourceNode> create() {
        std::shared_ptr<StreamSourceNode> node{new StreamSourceNode};
        node->addOutput();
        return node;
    }

    int setSourceHandle(std::shared_ptr<StreamHandle> stream_handle);

    void start() override;

    void stop() override;

    void pause() override;

    bool getLoop() const override;

    void setLoop(bool) override;

    TransportState state();

private:
    explicit StreamSourceNode();
    class StreamSourceNodeImpl;
    std::shared_ptr<StreamSourceNodeImpl> impl;
};

MAMMON_ENGINE_NAMESPACE_END