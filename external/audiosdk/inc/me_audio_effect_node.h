//
// Created by hw on 2019-08-14.
//

#pragma once
#include "me_node.h"
#include "ae_bus.h"
#include "ae_ringbuffer.h"
#include <atomic>
#include "ae_effect.h"
class InputBufferAdapter;

MAMMON_ENGINE_NAMESPACE_BEGIN

/**
 * @brief 封装Effect类加入图计算的节点
 *
 */
class MAMMON_EXPORT AudioEffectNode : public Node {
public:
    static std::shared_ptr<AudioEffectNode> create(std::shared_ptr<mammon::Effect> effect) {
        return std::shared_ptr<AudioEffectNode>(new AudioEffectNode(effect));
    }

    ~AudioEffectNode();

    int process(int out_port_id, RenderContext& rc) override;

    audiograph::NodeType type() const override {
        return audiograph::NodeType::AudioEffectNode;
    }

    std::shared_ptr<Node> getSharedPtr() override {
        return shared_from_this();
    }

    std::string getEffectName() const;

    /**
     * @brief 获取节点关联的Effect指针
     * @return Effect裸指针
     */
    mammon::Effect* getEffect() {
        return effect_storage_.get();
    };

    size_t getLatency() const override;

    bool cleanUp() override;

    void setEffect(std::shared_ptr<mammon::Effect> effect);

protected:
    void buildBusArray(RenderContext& rc);
    int process(mammon::Effect* effect, int out_port_id, RenderContext& rc);

private:
    explicit AudioEffectNode(std::shared_ptr<mammon::Effect> effect);
    InputBufferAdapter* adapter_;
    std::shared_ptr<mammon::Effect> effect_storage_;
    std::atomic<mammon::Effect*> effect_p_;
    std::vector<AudioStream> output_data_array_;

    std::vector<mammon::Bus> bus_array_;

    AudioEffectNode(const AudioEffectNode&) = delete;
    AudioEffectNode& operator=(const AudioEffectNode&) = delete;
};
MAMMON_ENGINE_NAMESPACE_END