//
// Created by chenyuezhao on 2019-05-14.
//

#pragma once
#include "ae_effect.h"

namespace mammon {
    class EchoX : public Effect {
    public:
        static constexpr const char* EFFECT_NAME = "delay";
        EchoX(int channels, int sample_rate);
        virtual ~EchoX() = default;

        void setParameter(const std::string& parameter_name, float val) override;

        const char* getName() const override {
            return EFFECT_NAME;
        }

        int process(std::vector<Bus>& bus_array) override;

        void reset() override {
        }

    private:
        DEF_PARAMETER(delayed_time_ms, "delayed_time_ms", 234.0f, 0, 900.0)
        DEF_PARAMETER(feedback, "feedback", 0.2f, 0, 1.0)
        DEF_PARAMETER(wet, "wet", 0.2f, 0, 1.0)
        DEF_PARAMETER(dry, "dry", 1.0f, 0, 1.0)

    private:
        class Impl;
        std::shared_ptr<Impl> impl_;
    };
}  // namespace mammon
