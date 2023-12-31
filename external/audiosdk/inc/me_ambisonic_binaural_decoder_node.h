//
// Created by Jon on 2020/2/11.
//

#ifndef AUDIO_EFFECT_AMBISONICBINAURALDECODER_H
#define AUDIO_EFFECT_AMBISONICBINAURALDECODER_H

#include "me_node.h"

#include <string>
#include <vector>
#include <memory>
#include <cmath>

MAMMON_ENGINE_NAMESPACE_BEGIN

class PartitionedFftFilter;

inline int GetPeriphonicAmbisonicOrderForChannel(size_t channel) {
    return static_cast<int>(sqrtf(static_cast<float>(channel)));
}
inline int GetPeriphonicAmbisonicDegreeForChannel(size_t channel) {
    const int order = GetPeriphonicAmbisonicOrderForChannel(channel);
    return static_cast<int>(channel) - order * (order + 1);
}

typedef std::vector<std::vector<float>> HrirsData;

class MAMMON_EXPORT HrirManager {
public:
    void createHrirsFromFile(const std::string& filename);

    void resampleHrirs(size_t target_sample_rate);

    size_t getNumChannel() {
        return num_channels_;
    };
    size_t getNumFrames() {
        return num_frames_;
    };
    size_t getSampleRate() {
        return sample_rate_;
    };

private:
    size_t num_channels_;
    size_t num_frames_;
    size_t sample_rate_;

    HrirsData hrirs_data_;
    friend class HrirManagerTest;
    friend class AmbisonicBinauralDecoderNodeTest;
    friend class AmbisonicBinauralDecoderNodeTest_Graph_Test;
    friend class AmbisonicBinauralDecoderNode;
};

class MAMMON_EXPORT AmbisonicBinauralDecoder {
public:
    AmbisonicBinauralDecoder() = delete;
    AmbisonicBinauralDecoder(HrirsData& hrirsData, size_t frames_per_buffer);
    void process(const AudioStream& input, AudioStream& output);

private:
    size_t frames_per_buffer_;
    std::vector<std::shared_ptr<PartitionedFftFilter>> sh_hrir_filters_;
    std::vector<float> filtered_input_;
};

/**
 * @brief Ambisonic 信号解码器
 *  TODO: Rotate
 *  TODO: crossfade
 */
class AmbisonicBinauralDecoderNode : public Node {
public:
    AmbisonicBinauralDecoderNode(int order, const std::string& hrir_filename);

    /**
     * @brief 创建解码器函数
     *
     * @param order 阶数
     * @param hrir_filename IR文件
     * @return std::shared_ptr<AmbisonicBinauralDecoderNode>
     */
    static std::shared_ptr<AmbisonicBinauralDecoderNode> create(int order, const std::string& hrir_filename) {
        std::shared_ptr<AmbisonicBinauralDecoderNode> node{new AmbisonicBinauralDecoderNode(order, hrir_filename)};
        //
        node->addInput((order + 1) * (order + 1));
        node->addOutput(2);
        return node;
    }

    int process(int port, RenderContext& rc) override;

    bool cleanUp() override {
        return true;
    };
    std::shared_ptr<Node> getSharedPtr() override {
        return shared_from_this();
    };
    audiograph::NodeType type() const override {
        return audiograph::NodeType::AmbisonicBinauralDecoderNode;
    }

    bool checkNumChannels(int num_channels) {
        return (order_ + 1) * (order_ + 1) == num_channels;
    };

    /**
     * @brief 获取阶数
     *
     * @return int
     */
    int order() {
        return order_;
    }

    /**
     * @brief 设置采样率
     *
     * @param sample_rate
     */
    void setSampleRate(int sample_rate) {
        hrir_manager_->resampleHrirs(sample_rate);
    }

    void setChannelMode(bool channel_mode) {
        channel_mode_ = channel_mode;
    }

private:
    int order_;
    std::string hrir_filename_;
    std::shared_ptr<HrirManager> hrir_manager_;
    std::unique_ptr<AmbisonicBinauralDecoder> ambisonic_binaural_decoder_;
    // if |channel_mode_| is true (default), ambisonic buffer data will read from one port's channels,
    // that is 4 channels are needed for first order scheme.
    // Otherwise, data will read from different ports' first channels, that is 4 ports are needed for first order
    // scheme.
    bool channel_mode_;
};

MAMMON_ENGINE_NAMESPACE_END

#endif  // AUDIO_EFFECT_AMBISONICBINAURALDECODER_H
