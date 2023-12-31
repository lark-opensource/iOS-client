#pragma once

#include "ae_effect.h"

namespace mammon {

    class LoudNorm2 : public Effect {
    public:
        static constexpr const char* EFFECT_NAME = "online_loudnorm2";

        LoudNorm2(int sample_rate, int num_channel);
        ~LoudNorm2();

        const char* getName() const override {
            return EFFECT_NAME;
        }

        void setParameter(const std::string& parameter_name, float val) override;

        int process(std::vector<Bus>& bus_array) override;

        void reset() override;

    private:
        // Target loudness in LUFS, default = -16, min = -20, max = -12
        DEF_PARAMETER(target_lufs_, "target_lufs", -16, -12, -20)

        class Impl;
        std::shared_ptr<Impl> impl_;
    };

}  // namespace mammon
