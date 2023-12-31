//
// Created by shidephen on 2019/12/23.
//

#pragma once

#ifndef AUDIO_EFFECT_AE_DEVICE_SOURCE_NODE_H
#define AUDIO_EFFECT_AE_DEVICE_SOURCE_NODE_H

#include "me_node.h"
#include "me_source_node.h"

MAMMON_ENGINE_NAMESPACE_BEGIN

/**
 * @brief 设备输入数据源
 * 通常是mic
 */
class MAMMON_EXPORT DeviceInputSourceNode : public Node, public SourceNode {
public:
    // Inherated from Node

    int process(int port, RenderContext& rc) override;

    std::shared_ptr<Node> getSharedPtr() override {
        return shared_from_this();
    }

    audiograph::NodeType type() const override {
        return audiograph::NodeType::DeviceInputSourceNode;
    }

    bool cleanUp() override;

    template <typename... TP>
    static std::shared_ptr<DeviceInputSourceNode> create(TP&&... params) {
        std::shared_ptr<DeviceInputSourceNode> node{new DeviceInputSourceNode(params...)};
        node->addOutput();
        return node;
    }

    size_t tryWriteQueue(const float* buf, size_t numFrame, size_t ch, size_t timeout_us);

    ~DeviceInputSourceNode();

    void start() override;

    void stop() override;

    void pause() override;

    bool getLoop() const override;

    void setLoop(bool) override;

    TransportState state();

private:
    explicit DeviceInputSourceNode(size_t device_id);
    class Impl;

    Impl* internals_;
};

MAMMON_ENGINE_NAMESPACE_END
#endif  // AUDIO_EFFECT_AE_DEVICE_SOURCE_NODE_H
