//
// Created by
//  ┬┌─┐┌┐┌
//  ││ ││││ Junjie Shi on 2020/5/18.
// └┘└─┘┘└┘ Copyright (c) 2020 ByteDance. All rights reserved.
//

#ifndef MAMMONSDK_ME_SPATIALIZER_NODE_H
#define MAMMONSDK_ME_SPATIALIZER_NODE_H

#include "me_graph_node.h"
#include "me_ambisonic_encoder_node.h"
#include "me_ambisonic_binaural_decoder_node.h"
#include "mammon_engine_type_defs.h"

MAMMON_ENGINE_NAMESPACE_BEGIN
class SpatialAudioContext;

class MAMMON_EXPORT SpatializerNode : public ElasticGraphNode {
public:
    static std::shared_ptr<SpatializerNode> create(SpatializerType type) {
        auto n = std::make_shared<SpatializerNode>(type);
        n->addInput();
        n->addOutput();
        return n;
    }

    SpatializerNode(SpatializerType type);

    audiograph::NodeType type() const override {
        return audiograph::NodeType::SpatializerNode;
    }

    /* SPATIAL AUDIO APIs */

    int setPosition(int id, float x, float y, float z);

    int setSourceSpread(int id, float spread_degree);

    void setSampleRate(int sr);

    void decoderUseChannelMode(bool channel_mode);

    std::shared_ptr<Node> addInput(size_t num_chan) override;

    std::shared_ptr<Node> addInput();

    std::shared_ptr<SpatialAudioContext> getSpatialAudioContext() {
        return sa_ctx;
    }

private:
    SpatializerType kernel_type;
    AmbisonicEncoderNode* encoder;
    AmbisonicBinauralDecoderNode* decoder;
    SinkNode* sink;
    std::shared_ptr<SpatialAudioContext> sa_ctx;
};

MAMMON_ENGINE_NAMESPACE_END

#endif  // MAMMONSDK_ME_SPATIALIZER_NODE_H
