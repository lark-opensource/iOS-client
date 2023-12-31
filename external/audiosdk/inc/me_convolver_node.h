//
// Created by
//  ┬┌─┐┌┐┌
//  ││ ││││ Junjie Shi on 2020/8/6.
// └┘└─┘┘└┘ Copyright (c) 2020 ByteDance. All rights reserved.
//

#pragma once
#include <memory>
#include "me_node.h"

MAMMON_ENGINE_NAMESPACE_BEGIN

class PartitionedFftFilter;

class ConvolverNode : public Node {
public:
    ConvolverNode();
    static std::shared_ptr<ConvolverNode> create();
    int process(int port, RenderContext& rc) override;
    bool cleanUp() override {
        return true;
    };
    std::shared_ptr<Node> getSharedPtr() override {
        return shared_from_this();
    };
    audiograph::NodeType type() const override {
        return audiograph::NodeType::ConvolverNode;
    }

    void setKernel(std::vector<float>& kernel);

private:
    std::vector<std::shared_ptr<PartitionedFftFilter>> filters_;
    bool kernel_ready_ = false;
    std::vector<float> kernel_;
    std::vector<float> legacy_kernel_;
};
MAMMON_ENGINE_NAMESPACE_END