//
// Created by manjia on 2020-09-30.
//

#pragma once

#include "ae_effect.h"

namespace mammon {

    class BiquadFilter : public Effect {
    public:
        enum class BiQuadFilterType { kLowPass, kHighPass };
        static constexpr const char* EFFECT_NAME = "biquad_filter";

        BiquadFilter(int sample_rate, int num_channel);
        virtual ~BiquadFilter() = default;

        void setParameter(const std::string& parameter_name, float val) override;
        const char* getName() const override {
            return EFFECT_NAME;
        }

        int process(std::vector<Bus>& bus_array) override;

        void reset() override;

    private:
        DEF_PARAMETER(freq, "freq", 100.0, 10.0, 20000.0)
        DEF_PARAMETER(gain, "gain", 1.0, 1.0, 10.0)
        DEF_PARAMETER(quality, "quality", 1.0, 1.0, 2.0)
        DEF_PARAMETER(filter_type, "filter_type", (float)BiQuadFilterType::kLowPass, (float)BiQuadFilterType::kLowPass,
                      (float)BiQuadFilterType::kHighPass)

    private:
        class Impl;
        std::shared_ptr<Impl> impl_;
    };

}  // namespace mammon
