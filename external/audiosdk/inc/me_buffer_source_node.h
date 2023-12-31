//
// Created by hw on 2019-08-02.
//

#pragma once

#include <atomic>
#include "me_audiostream.h"
#include "me_node.h"
#include "me_source_node.h"

MAMMON_ENGINE_NAMESPACE_BEGIN

/**
 * @brief 用内存中的数据作为源的节点
 * 内存中的数据为一帧数据长
 */
class MAMMON_EXPORT BufferSourceNode : public Node, public SourceNode {
public:
    template <typename... TP>
    static std::shared_ptr<BufferSourceNode> create(TP&&... params) {
        std::shared_ptr<BufferSourceNode> node{new BufferSourceNode(params...)};
        node->addOutput();
        return node;
    }

    int process(int out_port, RenderContext& rc) override;

    std::shared_ptr<Node> getSharedPtr() override {
        return shared_from_this();
    }

    audiograph::NodeType type() const override {
        return audiograph::NodeType::BufferSourceNode;
    }

    void start() override;

    void stop() override;

    void pause() override;

    void setLoop(bool) override;

    bool getLoop() const override;

    /**
     * @brief 设置内存数据源
     *
     * @param data_stream
     */
    void setSource(const std::shared_ptr<mammonengine::AudioStream>& data_stream);

    const mammonengine::AudioStream* getSource() const {
        return source_data_.get();
    }

protected:
    BufferSourceNode() = default;

    BufferSourceNode(const std::shared_ptr<mammonengine::AudioStream>& data_stream);

    std::shared_ptr<mammonengine::AudioStream> source_data_;

    std::atomic<bool> is_start_;

    std::atomic<bool> is_loop_;
};

}  // namespace mammon
