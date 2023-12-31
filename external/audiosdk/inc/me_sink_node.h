//
// Created by hw on 2019-07-29.
//

#pragma once
#include "me_node.h"
#include "me_graph.h"

MAMMON_ENGINE_NAMESPACE_BEGIN

/**
 * @brief 最终输出节点
 * 通常是音频流图的信号终点
 */
class MAMMON_EXPORT SinkNode : public Node {
public:
    static std::shared_ptr<SinkNode> create() {
        std::shared_ptr<SinkNode> node{new SinkNode};
        node->addInput();
        return node;
    }

    SinkNode() = default;

    /**
     * @brief 拉取计算好的数据
     *
     * @param port 端口号
     * @param rc 渲染上下文
     * @return const AudioStream*
     */
    const AudioStream* readInputs(int port, RenderContext& rc) {
        AudioGraph* graph = getGraph();
        if(graph) { graph->getExecutor()->currentStatus = GraphProcessStatus::kOK; }
        auto pinNode = pin(port);
        if (pinNode == nullptr) {
            return nullptr;
        }
        return pinNode->read(rc);
    }

    int process(int out_port_id, RenderContext& rc) final {
        return 0;
    }

    bool cleanUp() final {
        return true;
    }

    std::shared_ptr<Node> getSharedPtr() override {
        return shared_from_this();
    }

    audiograph::NodeType type() const override {
        return audiograph::NodeType::SinkNode;
    }

private:
    SinkNode(const SinkNode&) = delete;
    SinkNode& operator=(const SinkNode&) = delete;
};
MAMMON_ENGINE_NAMESPACE_END
