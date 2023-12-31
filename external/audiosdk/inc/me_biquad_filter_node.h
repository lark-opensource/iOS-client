//
// Created by shidephen on 2020/7/1.
//

#ifndef MAMMONSDK_ME_BIQUAD_FILTER_NODE_H
#define MAMMONSDK_ME_BIQUAD_FILTER_NODE_H

#include "me_node.h"

MAMMON_ENGINE_NAMESPACE_BEGIN

/**
 * @brief BiQuad Filter type
 *
 */
enum class BiQuadFilterType { kLowPass, kHighPass };

/**
 * @brief Biquad filter node like Web Audio
 *
 */
class MAMMON_EXPORT BiquadFilterNode : public Node {
public:
    // Inherated from Node
    static std::shared_ptr<BiquadFilterNode> create() {
        std::shared_ptr<BiquadFilterNode> node(new BiquadFilterNode);
        node->addOutput();
        node->addInput();
        return node;
    }

    int process(int out_port_id, RenderContext& rc) override;

    bool cleanUp() override;

    audiograph::NodeType type() const override {
        return audiograph::NodeType::BiquadFilterNode;
    }

    std::shared_ptr<Node> getSharedPtr() override {
        return shared_from_this();
    }

    // Personal
    ~BiquadFilterNode();

    /**
     * @brief Get/set frequency of filter node
     * 获取、设置截止频率
     * @return float
     */
    float frequency() const {
        return freq_;
    }
    void setFrequency(float f);

    /**
     * @brief Get/set Q(Quality) factor
     * 获取、设置Q值
     * @return float
     */
    float Q() const {
        return q_;
    }
    void setQ(float q);

    /**
     * @brief Get/set gain
     * 获取、设置gain
     * @return float
     */
    float gain() const {
        return gain_;
    }
    void setGain(float g);

    /**
     * @brief Get/set filter type
     * 获取、设置滤波器类型
     * @return BiQuadFilterType
     */
    BiQuadFilterType filterType() const {
        return filter_type_;
    }
    void setFilterType(BiQuadFilterType type);

private:
    BiquadFilterNode();
    float freq_;
    float gain_;
    float q_;
    BiQuadFilterType filter_type_;
    struct Impl;
    Impl* internal_;
};

MAMMON_ENGINE_NAMESPACE_END

#endif  // MAMMONSDK_ME_BIQUAD_FILTER_NODE_H
