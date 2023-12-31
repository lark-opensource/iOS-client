#pragma once
#include "me_buffer_source_node.h"

MAMMON_ENGINE_NAMESPACE_BEGIN

/**
 * @brief 在特定时间位置触发播放内存数据源的节点
 *
 */
class MAMMON_EXPORT PositionalBufferSourceNode : public BufferSourceNode {
public:
    template <typename... TP>
    static std::shared_ptr<PositionalBufferSourceNode> create(TP&&... params) {
        std::shared_ptr<PositionalBufferSourceNode> node{new PositionalBufferSourceNode(params...)};
        node->addOutput();
        return node;
    }

    audiograph::NodeType type() const override {
        return audiograph::NodeType::PositionalBufferSourceNode;
    }

    /**
     * @brief 设置播放位置
     * 单位是采样点
     * @param position 待设置的播放位置
     */
    void setPosition(TransportTime position);

    TransportTime getPosition() const {
        return position_;
    }

    int process(int port, RenderContext& rc) override;

    std::shared_ptr<Node> getSharedPtr() override {
        return shared_from_this();
    }

private:
    PositionalBufferSourceNode(const std::shared_ptr<AudioStream>& data, TransportTime position);

    TransportTime position_;
};
}