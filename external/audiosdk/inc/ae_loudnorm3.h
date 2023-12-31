#pragma once

#include "ae_effect.h"

namespace mammon {

class LoudNorm3 : public Effect {
public:
    static constexpr const char* EFFECT_NAME = "online_loudnorm3";

    LoudNorm3(int sample_rate, int num_channel, int block_size);
    ~LoudNorm3() override = default;

    const char* getName() const override {
        return EFFECT_NAME;
    }

    void setParameter(const std::string& parameter_name, float val) override;

    int process(std::vector<Bus>& bus_array) override;

    void reset() override;

    int getCachedDataSize();

private:
    // Target loudness in LUFS, default = -15, min = -20, max = -12
    DEF_PARAMETER(target_lufs_, "target_lufs", -15, -12, -20)
    DEF_PARAMETER(loudness_range_, "loudness_range", 3.f, 0.f, 10.f)
    DEF_PARAMETER(vad_threshold_, "vad_threshold", 0.9f, 0.f, 1.f)
    DEF_PARAMETER(vad_value_left_, "vad_value_left", 0.f, 0.f, 1.f)
    DEF_PARAMETER(vad_value_right_, "vad_value_right", 0.f, 0.f, 1.f)

    class Impl;
    std::shared_ptr<Impl> impl_;
};

}  // namespace mammon
