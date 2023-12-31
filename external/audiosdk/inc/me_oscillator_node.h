#pragma once

#include <atomic>

#include "me_node.h"
#include "me_source_node.h"

MAMMON_ENGINE_NAMESPACE_BEGIN

enum class OscillatorType {
    kSine,      ///< 正弦
    kSquare,    ///< 方波
    kSawTooth,  ///< 锯齿波
    kTriangle   ///< 三角波
};

/**
 * @brief 单频振荡器
 * 生成简单波形的发生器
 */
class MAMMON_EXPORT OscillatorNode : public Node, public SourceNode {
public:
    static std::shared_ptr<OscillatorNode> create() {
        std::shared_ptr<OscillatorNode> node = std::make_shared<OscillatorNode>();
        node->addOutput();
        return node;
    }

    OscillatorNode();
    ~OscillatorNode();

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
    void start() override;

    /**
     * @brief 停止计算
     *
     */
    void stop() override;

    void pause() override;

    bool isStarted() const {
        return playing_.load();
    }

    void setLoop(bool) override {
    }

    bool getLoop() const override {
        return false;
    }

    /**
     * @brief 获取波形形状
     *
     * @return OscillatorType
     */
    OscillatorType getOscType() const {
        return type_;
    }

    /**
     * @brief 设置波形形状
     *
     * @param type
     */
    void setOscType(OscillatorType type);

    /**
     * @brief
     *
     * @return float 获取频率
     */
    float frequency() const {
        return freq_;
    }

    /**
     * @brief 设置频率
     *
     * @param freq
     */
    void setFrequency(float freq);

private:
    std::atomic<OscillatorType> type_;
    std::atomic<float> freq_;
    std::atomic<bool> playing_;
};

MAMMON_ENGINE_NAMESPACE_END
