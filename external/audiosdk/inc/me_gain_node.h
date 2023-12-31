//
// Created by shidephen on 2020/5/17.
//

#pragma once
#ifndef MAMMONSDK_ME_GAIN_NODE_H
#define MAMMONSDK_ME_GAIN_NODE_H

#include "me_node.h"
#include <atomic>

MAMMON_ENGINE_NAMESPACE_BEGIN

class MAMMON_EXPORT GainNode : public Node {
public:
    static std::shared_ptr<GainNode> create() {
        std::shared_ptr<GainNode> node = std::shared_ptr<GainNode>(new GainNode);
        node->addInput();
        node->addOutput();

        return node;
    }

    ~GainNode() = default;

    // Inherited from Node
    int process(int port, RenderContext& rc) override;

    bool cleanUp() override {
        return true;
    }

    audiograph::NodeType type() const override {
        return audiograph::NodeType::GainNode;
    }

    std::shared_ptr<Node> getSharedPtr() override {
        return shared_from_this();
    }

    void setGain(float g);
    float getGain() const;

private:
    explicit GainNode();
    std::atomic<float> gain_;
    std::atomic<float> target_gain_;
};

MAMMON_ENGINE_NAMESPACE_END

#endif  // MAMMONSDK_ME_GAIN_NODE_H
