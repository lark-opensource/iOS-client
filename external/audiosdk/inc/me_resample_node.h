//
// Created by william on 2020/5/9.
//

#pragma once
#include "me_node.h"

MAMMON_ENGINE_NAMESPACE_BEGIN

class MAMMON_EXPORT ResampleNode : public Node {
public:
    static std::shared_ptr<ResampleNode> create(float ratio) {
        auto node = std::shared_ptr<ResampleNode>(new ResampleNode(ratio));

        node->addInput();
        node->addOutput();

        return node;
    }

    int process(int out_port_id, RenderContext& rc) override;

    std::shared_ptr<Node> getSharedPtr() override {
        return shared_from_this();
    }

    void setResampleRatio(float ratio);

    float getResampleRatio() const;

    audiograph::NodeType type() const override {
        return audiograph::NodeType::ResampleNode;
    }

private:
    explicit ResampleNode(float ratio);

    class Impl;
    std::shared_ptr<Impl> impl_;
};
}
