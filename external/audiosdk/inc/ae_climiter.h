//
// Created by william on 2019-08-19.
//

#pragma once
#include "ae_effect.h"

namespace mammon {
    class CLimiterX : public Effect {
    public:
        static constexpr const char* EFFECT_NAME = "climiter";

        explicit CLimiterX(int num_channels, int sample_rate = 0);
        void setParameter(const std::string& parameter_name, float val) override;
        const char* getName() const override {
            return EFFECT_NAME;
        }

        size_t getLatency() const override;

        int process(std::vector<Bus>& bus_array) override;
        void reset() override {
        }

    private:
        DEF_PARAMETER(gate_, "gate", 0.99, 0, 1)
        DEF_PARAMETER(pregain_dB_, "pregain_dB", 0, -100, 100)
//        DEF_PARAMETER(release_time_ms_, "release_time_ms",200,0,1000)
//        DEF_PARAMETER(look_ahead_time_, "look_ahead_time",3,0,1000)
        DEF_PARAMETER(climiter_type_, "climiter_type",0,0,1)


    private:
        class Impl;
        class ImplV1;
        class ImplV2;
        std::shared_ptr<Impl> impl_V2;
        std::shared_ptr<Impl> real_impl;
        bool type_setted_;
    };
}  // namespace mammon
