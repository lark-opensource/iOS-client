#pragma once

#include "ae_effect.h"

namespace mammon {

    class LoudNorm : public Effect {
    public:
        static constexpr const char* EFFECT_NAME = "online_loudnorm";

        LoudNorm(int sample_rate, int num_channel);
        ~LoudNorm();

        const char* getName() const override {
            return EFFECT_NAME;
        }

        void setParameter(const std::string& parameter_name, float val) override;

        int process(std::vector<Bus>& bus_array) override;

        void reset() override;

    private:
        // Target loudness in LUFS, default = -16, min = -20, max = -12
        DEF_PARAMETER(target_lufs_, "target_lufs", -16, -12, -20)

        // Source loudness in LUFS, peak, loudness range, threshold
        // if provided, linear gain will be calculated and fixed at that value
        // else, perform online normalization with varying gain
        DEF_PARAMETER(source_lufs_, "source_lufs", 0, -70, 0)
        DEF_PARAMETER(source_peak_, "source_peak", 99, 0, 1)
        DEF_PARAMETER(source_lra_, "source_lra", 10, 0, 30)
        DEF_PARAMETER(source_threshold_, "source_threshold", -50, -70, 0)
        DEF_PARAMETER(noise_threshold_, "noise_threshold", -50, -70, -30)

        class Impl;
        std::shared_ptr<Impl> impl_;
    };

}  // namespace mammon
