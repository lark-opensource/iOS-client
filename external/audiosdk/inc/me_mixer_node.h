//
// Created by hw on 2019-08-07.
//

#pragma once
#include "me_node.h"
#include "mammon_engine_defs.h"

MAMMON_ENGINE_NAMESPACE_BEGIN

/**
 * @brief 混音器节点，会将多个port的输入合成1个
 * 通过增加input来增加输入
 */
class MAMMON_EXPORT MixerNode : public Node {
public:
    static std::shared_ptr<MixerNode> create() {
        std::shared_ptr<MixerNode> node{new MixerNode};
        node->addInput();
        node->addOutput();

        return node;
    }

    audiograph::NodeType type() const override {
        return audiograph::NodeType::MixerNode;
    }

    int process(int port, RenderContext& rc) override;

    std::shared_ptr<Node> getSharedPtr() override {
        return shared_from_this();
    }

private:
    MixerNode() = default;
};
}
