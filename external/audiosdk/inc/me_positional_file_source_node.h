#pragma once

#include "me_file_source_node.h"
#include "me_positional_node.h"

MAMMON_ENGINE_NAMESPACE_BEGIN

/**
 * @brief 在特定时间触发播放的文件数据源节点
 *
 */
class MAMMON_EXPORT PositionalFileSourceNode : public FileSourceNode, PositionalNode {
public:
    static std::shared_ptr<PositionalFileSourceNode> create(std::shared_ptr<mammon::FileSource> source,
                                                            TransportTime position) {
        std::shared_ptr<PositionalFileSourceNode> node{new PositionalFileSourceNode(source, position)};
        node->addOutput();
        return node;
    }

    std::shared_ptr<Node> getSharedPtr() override {
        return shared_from_this();
    }

    audiograph::NodeType type() const override {
        return audiograph::NodeType::PositionalFileSourceNode;
    }

    /**
     * @brief 设置开始播放的位置
     *
     * @param position 开始播放的位置
     */
    void startAtTime(TransportTime position) override;

    void stopAtTime(TransportTime pos) override {
    }

private:
    PositionalFileSourceNode(std::shared_ptr<mammon::FileSource> source, TransportTime position);
};

MAMMON_ENGINE_NAMESPACE_END