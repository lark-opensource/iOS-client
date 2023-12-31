//
// Created by huanghao.blur on 2019/12/31.
//

#pragma once

#ifndef AUDIO_EFFECT_AE_TRIGGER_NODE_H
#define AUDIO_EFFECT_AE_TRIGGER_NODE_H

#include "me_node.h"
#include <functional>
#include <atomic>

MAMMON_ENGINE_NAMESPACE_BEGIN

/**
 * @brief Trigger node for triggering a custom function frame by frame
 * 一个每帧回调特定函数的节点，可以获取当时的rc和数据流
 *
 */
class MAMMON_EXPORT TriggerNode : public Node {
public:
    template <typename... TP>
    static std::shared_ptr<TriggerNode> create(TP&&... params) {
        std::shared_ptr<TriggerNode> node{new TriggerNode(params...)};
        node->addOutput();
        node->addInput();

        return node;
    }

    std::shared_ptr<Node> getSharedPtr() override {
        return shared_from_this();
    }

    audiograph::NodeType type() const override {
        return audiograph::NodeType::TriggerNode;
    }

    ~TriggerNode() final;

    int process(int port, RenderContext& rc) override;

    /**
     * @brief Set a function object for callback
     * 设置一个function对象来回调
     * @param f
     */
    void setFunction(std::function<void(TriggerNode*, RenderContext)>&& f);

    bool cleanUp() override;

private:
    TriggerNode(bool async = true);

    using TriggerNodeCallbackFunc = std::function<void(TriggerNode*, RenderContext)>;
    std::shared_ptr<TriggerNodeCallbackFunc> func_storage_;
    std::atomic<TriggerNodeCallbackFunc*> p_func_{nullptr};

    struct Impl;
    Impl* internals_;
};

MAMMON_ENGINE_NAMESPACE_END

#endif  // AUDIO_EFFECT_AE_TRIGGER_NODE_H
