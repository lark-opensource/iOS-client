//
// Created by chenyuezhao on 2019-05-13.
//

#pragma once
#include "ae_effect.h"

namespace mammon {
    class VibratoX : public Effect {
    public:
        static constexpr const char* EFFECT_NAME = "vibrato";
        VibratoX(int channel_number, int sample_rate);
        virtual ~VibratoX();

        const char* getName() const override {
            return EFFECT_NAME;
        }

        void setParameter(const std::string& parameter_name, float val) override;

        int process(std::vector<Bus>& bus_array) override;

        void reset() override {
        }

    private:
        DEF_PARAMETER(rate, "rate", 1.0f, 0.0, 2.0)
        DEF_PARAMETER(semitones, "semitones", 1.0f, 0, 2.0)
    private:
        class Impl;
        std::shared_ptr<Impl> impl_;
    };
}  // namespace mammon
