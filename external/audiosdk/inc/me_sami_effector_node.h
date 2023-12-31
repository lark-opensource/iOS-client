//
// Created by william on 2020/4/27.
//

#ifndef MAMMONSDK_SRC_NODES_ME_SAMI_EFFECTOR_NODE_H
#define MAMMONSDK_SRC_NODES_ME_SAMI_EFFECTOR_NODE_H

#include "me_node.h"

MAMMON_ENGINE_NAMESPACE_BEGIN
class MAMMON_EXPORT SamiEffectorNode : public Node {
public:
    static std::shared_ptr<SamiEffectorNode> create(int effector_type, size_t block_size) {
        auto node = std::shared_ptr<SamiEffectorNode>(new SamiEffectorNode(effector_type, block_size));

        node->addInput();
        node->addOutput();

        return node;
    }

    int process(int out_port_id, mammonengine::RenderContext& rc) override;

    std::shared_ptr<Node> getSharedPtr() override {
        return shared_from_this();
    }

    void pushMidiEvent(int port_index, int midi_type, int channel, int second_byte, int third_byte);

    void pushParameter(int port_number, int parameter_index, float value);

    void setResourcePath(const std::string& path);

    bool loadFromDescFile(const std::string& desc_path);

    audiograph::NodeType type() const override {
        return audiograph::NodeType::SamiEffectorNode;
    }

    // override
    virtual NodeOutput* pout(size_t idx) override;
    virtual Node* connect(Node* rhs) override;

private:
    explicit SamiEffectorNode(int effect_type, size_t block_size);


private:
    class Impl;
    std::shared_ptr<Impl> impl_;
};

MAMMON_ENGINE_NAMESPACE_END

#endif  // MAMMONSDK_SRC_NODES_ME_SAMI_EFFECTOR_NODE_H
