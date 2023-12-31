#pragma once

#include "ae_effect.h"

namespace mammon {
    class AudioPreprocess : public Effect {
    public:
        static constexpr const char* EFFECT_NAME = "preprocess";

        explicit AudioPreprocess(int samplerate, int channels);
        void reset() override;

        void setParameter(const std::string& parameter_name, float val) override;
        const char* getName() const override {
            return EFFECT_NAME;
        }

        int process(std::vector<Bus>& bus_array) override;
        size_t getLatency() const override;

        int getDelayTimeInMs() const;

    private:
        // Automatic gain control
        DEF_PARAMETER(enable_agc_, "enable_agc", 1, 0, 1)  // 0 or 1
        DEF_PARAMETER(target_level_, "target_level", 3, 0, 100)
        DEF_PARAMETER(gain_db_, "gain_db", 9, 0, 100)
        DEF_PARAMETER(enable_limiter_, "enable_limiter", 1, 0, 1)  // 0 or 1
        // also have two virtual parameters: "input_mic_level" and "adaptive_mode"
        // setParameter("input_mic_level", 127), default 127, range: [0, 255]
        // setParameter("adaptive_mode", 1), default 0, range: 0 or 1

        // Noise suppression
        DEF_PARAMETER(enable_ns_, "enable_ns", 1, 0, 1)  // 0 or 1
        DEF_PARAMETER(quantile_, "quantile", 0.2, 0.15, 0.25)
        DEF_PARAMETER(noise_suppress_, "noise_suppress", -70, -100, 0)
        DEF_PARAMETER(sparseness_measure_, "sparseness_measure", 1.1, 0.71, 1.1)

        // Echo cancellation
        DEF_PARAMETER(enable_aec_, "enable_aec", 1, 0, 1)  // 0 or 1
        DEF_PARAMETER(nlp_mode_, "nlp_mode", 0, -1, 2)
        DEF_PARAMETER(adjust_suppressor_gain_, "adjust_suppressor_gain", 0, 0, 1)

    private:
        class Impl;
        std::shared_ptr<Impl> impl_;
    };
}  // namespace mammon
