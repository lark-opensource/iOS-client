//
// Created by william on 2019-07-17.
//

#pragma once
#include "ae_effect.h"

namespace mammon {
    class NoiseSuppression : public Effect {
    public:
        static constexpr const char* EFFECT_NAME = "noise_suppression";

        explicit NoiseSuppression(int sample_rate, int num_channels);
        virtual ~NoiseSuppression() = default;

        const char* getName() const override {
            return EFFECT_NAME;
        }

        size_t getRequiredBlockSize() const override;
        int process(std::vector<Bus>& bus_array) override;

        void setParameter(const std::string& parameter_name, float val) override;
        DEF_PARAMETER(quantile_, "quantile", 0.2, 0.15, 0.25)
        DEF_PARAMETER(noise_suppress_, "noise_suppress", -70, -100, 0)
        DEF_PARAMETER(sparseness_measure_, "sparseness_measure", 1.1, 0.71, 1.1)

        void reset() override {
        }

    private:
        class Impl;
        std::shared_ptr<Impl> impl_;
    };

}  // namespace mammon
