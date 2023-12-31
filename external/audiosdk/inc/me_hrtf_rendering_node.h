//
// Created by lvzhuliang on 2020/6/3.
//

#ifndef MAMMONSDK_ME_HRTF_RENDERING_NODE_H
#define MAMMONSDK_ME_HRTF_RENDERING_NODE_H

#include <iostream>
#include <vector>
#include <fstream>
#include <algorithm>
#include <memory>
#include "me_node.h"

MAMMON_ENGINE_NAMESPACE_BEGIN
class SpatialAudioContext;
class HrirReader {
public:
    explicit HrirReader(const std::string& path);
    std::vector<std::vector<float>> getIR(const std::vector<float>& pos, size_t target_sr);

    std::vector<std::vector<float>> resample(size_t target_sr, std::vector<std::vector<float>>& orig_ir);

private:
    long nums_measurements_;
    long nums_ir_samples_;
    long nums_receivers_;
    double samplerate_;
    std::vector<std::vector<float>> getIR_from_file(const std::vector<float>& position);
    void remap_position(std::vector<float>& position_map_orig);
    void remap_ir_data(std::vector<float>& ir_data_orig);
    std::vector<std::vector<std::vector<float>>> IR_data_;
    std::vector<std::vector<float>> position_map_;

    float radius_;
};

class HrtfRenderingNode : public Node {
public:
    HrtfRenderingNode(std::string& hrir_file);
    static std::shared_ptr<HrtfRenderingNode> create(std::string& hrir_file) {
        std::shared_ptr<HrtfRenderingNode> node{new HrtfRenderingNode(hrir_file)};
        node->addInput(2);
        node->addOutput(2);
        return node;
    };

    int process(int port, RenderContext& rc) override;
    bool cleanUp() override {
        return true;
    };
    std::shared_ptr<Node> getSharedPtr() override {
        return shared_from_this();
    };
    audiograph::NodeType type() const override {
        return audiograph::NodeType::HrtfRenderingNode;
    }
    void bindContext(std::shared_ptr<SpatialAudioContext> sa_ctx);

private:
    void getIR(size_t samplerate);
    std::shared_ptr<HrirReader> hrir_reader_;
    std::shared_ptr<SpatialAudioContext> sa_ctx_;
    std::vector<std::vector<std::vector<float>>> hrir_;
    size_t hrir_len_;
    std::vector<std::vector<float>> overlap_;
    std::vector<std::vector<std::vector<float>>> tail_;
    std::vector<std::vector<std::vector<float>>> out_buffer_tail_;
    std::vector<float> win_;
};

MAMMON_ENGINE_NAMESPACE_END

#endif  // MAMMONSDK_ME_HRTF_RENDERING_NODE_H