//
// Created by huanghao.blur on 2020/1/13.
//

#pragma once
#ifndef AUDIO_EFFECT_AE_NOISE_NODE_H
#define AUDIO_EFFECT_AE_NOISE_NODE_H

#include <atomic>
#include "me_node.h"
#include "me_source_node.h"

MAMMON_ENGINE_NAMESPACE_BEGIN

enum class NoiseType {
    kGaussian  ///< 高斯噪声
};

/**
 * @brief 噪波发生器
 *
 */
class MAMMON_EXPORT NoiseNode : public Node, public SourceNode {
public:
    static std::shared_ptr<NoiseNode> create() {
        std::shared_ptr<NoiseNode> node{new NoiseNode};
        node->addOutput();
        return node;
    }

    virtual ~NoiseNode();

    int process(int out_port, RenderContext& rc) override;

    bool cleanUp() override;

    std::shared_ptr<Node> getSharedPtr() override {
        return shared_from_this();
    }

    audiograph::NodeType type() const override {
        return audiograph::NodeType::OscillatorNode;
    }

    /**
     * @brief 开始计算
     *
     */
    void start() override {
        playing_ = true;
    }

    /**
     * @brief 停止计算
     *
     */
    void stop() override {
        playing_ = false;
    }

    void pause() override;

    void setLoop(bool) override {
    }

    bool getLoop() const override {
        return false;
    }

private:
    NoiseNode();
    std::atomic<bool> playing_;
    std::atomic<NoiseType> type_;

    struct Impl;
    Impl* internal_;
};

MAMMON_ENGINE_NAMESPACE_END

#endif  // AUDIO_EFFECT_AE_NOISE_NODE_H
