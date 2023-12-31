//
// Created by william on 2019-04-18.
//

#pragma once

#include <vector>
#include "ae_defs.h"
#include "ae_effect.h"
namespace mammon {
    class MAMMON_EXPORT OnsetDetector : public Effect {
    public:
        static constexpr const char* EFFECT_NAME = "onset_detection";

        OnsetDetector(int sample_rate);

        const char* getName() const override {
            return EFFECT_NAME;
        }

        int process(std::vector<Bus>& bus_array) override;

        const std::vector<std::pair<float, float>>& getDetectedResult() const;

        void setParameter(const std::string& parameter_name, float val) override;

        void reset() override {
        }

        //====================Parameters================================
    private:
        DEF_PARAMETER(threshold_, "threshold", 50.0f, 40, 200)
        class Impl;
        std::shared_ptr<Impl> impl_;
    };
}  // namespace mammon