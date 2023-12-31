
//
// Created by
//  ┬┌─┐┌┐┌
//  ││ ││││ Junjie Shi on 2020/3/16.
// └┘└─┘┘└┘ Copyright (c) 2020 ByteDance. All rights reserved.
//

#ifndef AUDIO_EFFECT_AE_AMBISONIC_ENCODER_NODE_H
#define AUDIO_EFFECT_AE_AMBISONIC_ENCODER_NODE_H

#include "me_node.h"
#include "ae_math_utils.h"
#include <memory>
#include <unordered_map>
#include <tuple>
#include <cmath>

MAMMON_ENGINE_NAMESPACE_BEGIN

class SpatialAudioContext;

// Returns ACN channel sequence from a degree and order of a spherical harmonic.
inline int AcnSequence(int degree, int order) {
    return degree * degree + degree + order;
}

// Returns normalization factor for Schmidt semi-normalized spherical harmonics
// used in AmbiX.
inline float Sn3dNormalization(int degree, int order) {
    return std::sqrt((2.0f - ((order == 0) ? 1.0f : 0.0f)) * mammon::factorial(degree - std::abs(order)) /
                     mammon::factorial(degree + std::abs(order)));
}

// Returns the number of spherical harmonics for a periphonic ambisonic sound
// field of |ambisonic_order|.
inline size_t GetNumPeriphonicComponents(int ambisonic_order) {
    return static_cast<size_t>((ambisonic_order + 1) * (ambisonic_order + 1));
}

class AmbisonicEncoder;

/**
 * @brief Ambisonic 编码器
 * 把3D空间中的声源映射成n阶Ambisonic信号
 * 一般需要配合Decoder使用
 */
class MAMMON_EXPORT AmbisonicEncoderNode : public Node {
public:
    AmbisonicEncoderNode(int order);

    static std::shared_ptr<AmbisonicEncoderNode> create(int order) {
        std::shared_ptr<AmbisonicEncoderNode> node{new AmbisonicEncoderNode(order)};
        node->addInput(2);
        node->addOutput((order + 1) * (order + 1));
        return node;
    }

    int process(int port, RenderContext& rc) override;

    bool cleanUp() override {
        return true;
    };
    std::shared_ptr<Node> getSharedPtr() override {
        return shared_from_this();
    };
    audiograph::NodeType type() const override {
        return audiograph::NodeType::AmbisonicEncoderNode;
    }

    int order() {
        return order_;
    }

    void bindContext(std::shared_ptr<SpatialAudioContext> ctx) {
        sa_ctx = std::move(ctx);
    }

    int check_lut();

private:
    int order_;
    std::shared_ptr<AmbisonicEncoder> ambisonic_encoder_;
    std::shared_ptr<SpatialAudioContext> sa_ctx;
};

MAMMON_ENGINE_NAMESPACE_END

#endif  // AUDIO_EFFECT_AE_AMBISONIC_ENCODER_NODE_H
