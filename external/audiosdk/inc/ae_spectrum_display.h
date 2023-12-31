//
// Created by william on 2019-07-02.
//

#pragma once

#include "ae_effect.h"

namespace mammon {
    class MAMMON_EXPORT SpecDisplay : public Effect {
    public:
        static constexpr const char* EFFECT_NAME = "spectrum_display";

        SpecDisplay(int sample_rate);

        const char* getName() const override {
            return EFFECT_NAME;
        }

        void setParameter(const std::string& param_name, float val) override;

        const std::vector<std::pair<float, std::vector<float>>>& getSpectrumSequence() const;

        int process(std::vector<Bus>& bus_array) override;

        void reset() override {
        }

    private:
        DEF_PARAMETER(spec_length_, "spec_length", 50, 50, 512)
        DEF_PARAMETER(spec_freq_, "spec_freq", 10)

    private:
        std::vector<std::pair<float, std::vector<float>>> spec_seq_;
        class Impl;
        std::shared_ptr<Impl> impl_;
    };
}  // namespace mammon
