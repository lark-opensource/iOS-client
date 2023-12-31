//
// Created by william on 2019-04-19.
//

#pragma once
#include "ae_effect.h"
#include "ae_macros.h"

namespace mammon {
    class F0Detector : public Effect {
    public:
        static constexpr const char* EFFECT_NAME = "f0_detection";

        F0Detector(int sample_rate);

        const char* getName() const override {
            return EFFECT_NAME;
        }

        int process(std::vector<Bus>& bus_array) override;

        const std::vector<std::pair<float, float>>& getDetectedResult() const;

        void setParameter(const std::string& parameter_name, float val) override;

        void reset() override {
        }

    private:
        DEF_PARAMETER(f0_min_, "f0_min", 40.0)
        DEF_PARAMETER(f0_max_, "f0_max", 650.0)

    private:
        class Impl;
        std::shared_ptr<Impl> impl_;
        DISALLOW_COPY_AND_ASSIGN(F0Detector);
    };
}  // namespace mammon
