//
// Created by william on 2019/12/11.
//

#pragma once
#include "ae_effect.h"

namespace mammon {
    class AGC : public Effect {
    public:
        static constexpr const char* EFFECT_NAME = "agc";

        explicit AGC(int sample_rate, int num_channel);

        const char* getName() const override {
            return EFFECT_NAME;
        }

        void reset() override;
        int process(std::vector<Bus>& bus_array) override;
        void setParameter(const std::string& parameter_name, float val) override;

    private:
        DEF_PARAMETER(target_level_, "target_level", 3, 0, 100)
        DEF_PARAMETER(gain_db_, "gain_db", 9, 0, 100)
        DEF_PARAMETER(enable_limiter_, "enable_limiter", 1, 0, 1)  // 0 or 1
        // also have two virtual parameters: "input_mic_level" and "adaptive_mode"
        // setParameter("input_mic_level", 127), default 127, range: [0, 255]
        // setParameter("adaptive_mode", 1), default 0, range: 0 or 1

    private:
        class Impl;
        std::shared_ptr<Impl> impl_;
    };
}  // namespace mammon
