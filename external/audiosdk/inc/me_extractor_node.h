//
// Created by shidephen on 2020/1/10.
//

#pragma once

#ifndef AUDIO_EFFECT_AE_EXTRACTOR_NODE_H
#define AUDIO_EFFECT_AE_EXTRACTOR_NODE_H

#include "me_node.h"
#include "ae_extractor.h"
#include <atomic>

MAMMON_ENGINE_NAMESPACE_BEGIN

/**
 * @brief 提取音频信号的节点
 *
 */
class MAMMON_EXPORT ExtractorNode : public Node {
public:
    static std::shared_ptr<ExtractorNode> create(std::shared_ptr<mammon::Extractor> e) {
        std::shared_ptr<ExtractorNode> n = std::shared_ptr<ExtractorNode>(new ExtractorNode(e));
        n->addInput();
        n->addOutput();
        return n;
    }

    ~ExtractorNode() final = default;

    int process(int, RenderContext&) override;

    audiograph::NodeType type() const override {
        return audiograph::NodeType::ExtractorNode;
    }

    std::shared_ptr<Node> getSharedPtr() override {
        return shared_from_this();
    }

    /**
     * @brief 获得现有的Extractor对象
     *
     * @return std::shared_ptr<Extractor>&
     */
    std::shared_ptr<mammon::Extractor>& getExtractor() {
        return extractor_storage_;
    }

    void setExtractor(std::shared_ptr<mammon::Extractor> new_extractor);

    bool cleanUp() override;

    void setParameter(const std::string& param_name, float param_val);

    void setParameter(const std::string& param_name, const std::string& param_str_val);

private:
    int process(mammon::Extractor* extractor, int out_port, RenderContext& rc);

private:
    explicit ExtractorNode(std::shared_ptr<mammon::Extractor> e);
    std::shared_ptr<mammon::Extractor> extractor_storage_;
    std::atomic<mammon::Extractor*> extractor_p_;

    float* bus_data_[2];
    std::vector<mammon::Bus> bus_arr_;
};

MAMMON_ENGINE_NAMESPACE_END

#endif  // AUDIO_EFFECT_AE_EXTRACTOR_NODE_H
