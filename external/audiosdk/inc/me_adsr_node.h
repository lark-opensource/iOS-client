//
// Created by Jon on 2020/2/5.
//

#pragma once

#include "me_node.h"
#include <atomic>

MAMMON_ENGINE_NAMESPACE_BEGIN
/**
 * @brief ADSR节点，专门用来触发键控
 * ADSR = Attach Decay Sustain Release
 * <a href="https://en.wikipedia.org/wiki/Envelope_(music)" />
 */
class MAMMON_EXPORT ADSRNode : public Node {
public:
    ADSRNode();

    /**
     * @brief 控制音源开始发声
     * Trigger Key on
     * 进入Attach阶段
     */
    void keyOn();
    /**
     * @brief 控制音源停止发声
     * Trigger Key off
     * 进入Release阶段
     */
    void keyOff();

    /**
     * @brief Set Attack target level
     * Pick value of the envelope, eg. 1.0
     * 设置attack的峰值，相当于包络定点，一般1就是信号的最大值
     * @param attack_target
     */
    void setAttackTarget(float attack_target);
    /**
     * @brief Set the Attack Time to reach the target
     * 设置attack阶段到包络最大值的时间（启动时间）
     *
     * @param attack_time second 单位秒
     */
    void setAttackTime(float attack_time);
    /**
     * @brief Set the Sustain Level
     * 设置sustain阶段保持的声音level，一般最大是1
     * @param sustain_level
     */
    void setSustainLevel(float sustain_level);
    /**
     * @brief Set the Decay Time
     * Set the time decaying from attach level to sustain level
     * 设置从attach level下降到sustain level的时间
     * @param decay_time second 单位秒
     */
    void setDecayTime(float decay_time);
    /**
     * @brief Set the Release Time
     * Set the time decay from sustain level to 0.0. Triggered by keyOff
     * 设置从sustain level衰减到0音量的时间，由keyOff函数触发
     * @param release_time second 单位秒
     */
    void setReleaseTime(float release_time);

    // get系列
    float getAttackTarget() {
        return target_;
    }
    float getAttackTime() {
        return attack_time_;
    }
    float getSustainLevel() {
        return sustain_level_;
    }
    float getDecayTime() {
        return decay_time_;
    }
    float getReleaseTime() {
        return release_time_;
    }

    // 继承接口
    static std::shared_ptr<ADSRNode> create() {
        std::shared_ptr<ADSRNode> node{new ADSRNode()};
        node->addInput();
        node->addOutput();

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
        return audiograph::NodeType::ADSRNode;
    }

private:
    void setAttackIncrement(float attack_increment);
    void setDecayIncrement(float decay_increment);
    void setReleaseIncrement(float release_increment);

    std::atomic<float> sampling_rate_;

    float value_;
    std::atomic<float> target_;
    std::atomic<float> sustain_level_;
    std::atomic<float> attack_time_;   // [s]
    std::atomic<float> decay_time_;    // [s]
    std::atomic<float> release_time_;  // [s]

    std::atomic<float> attack_increment_;
    std::atomic<float> decay_increment_;
    std::atomic<float> release_increment_;

    enum ADSR_STATE { ATTACK = 0, DECAY, SUSTAIN, RELEASE, IDLE };
    std::atomic<ADSR_STATE> state_;

    float tick();
    void setSamplingRate(int sampling_rate);
};

MAMMON_ENGINE_NAMESPACE_END
