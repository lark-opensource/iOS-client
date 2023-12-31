//
// Created by
//  ┬┌─┐┌┐┌
//  ││ ││││ Junjie Shi on 2020/5/25.
// └┘└─┘┘└┘ Copyright (c) 2020 ByteDance. All rights reserved.
//

#pragma once

#include "me_node.h"
#include "resonance_audio_api.h"
#include <vector>
#include <unordered_map>
#include <memory>

MAMMON_ENGINE_NAMESPACE_BEGIN
class ResonanceNode : public Node {
    // NOTE: This class is a wrapper of resonance and only used for testing. Don't use it in product.
public:
    struct Position {
        Position() {
            x = 0;
            y = 0;
            z = 0;
        }
        Position(float _x, float _y, float _z) {
            x = _x;
            y = _y;
            z = _z;
        }
        float x;
        float y;
        float z;
    };
    explicit ResonanceNode(int order) : order_(order), ra_api_(nullptr){};
    ~ResonanceNode();

    static std::shared_ptr<ResonanceNode> create(int order) {
        auto n = std::make_shared<ResonanceNode>(order);
        n->addInput();
        n->addOutput(2);
        return n;
    }

    bool init(int num_channel, int frames_per_buffer, int sample_rate);
    int process(int out_port_id, RenderContext& rc) override;
    virtual std::shared_ptr<Node> getSharedPtr() override {
        return shared_from_this();
    };

    audiograph::NodeType type() const override {
        return audiograph::NodeType::ResonanceNode;
    }

    void setPosition(int id, float x, float y, float z);

    void setSourceSpread(int id, float spread_degree);

private:
    int order_;
    vraudio::ResonanceAudioApi* ra_api_;
    std::unordered_map<int, Position> position_table_;
    std::unordered_map<int, float> spread_table_;
};

MAMMON_ENGINE_NAMESPACE_END
