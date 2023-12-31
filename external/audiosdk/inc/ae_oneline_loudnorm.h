//
// Created by LIJING on 2021/3/9.
//

#ifndef AUDIO_EFFECT_AE_ONELINE_LOUDNORM_H
#define AUDIO_EFFECT_AE_ONELINE_LOUDNORM_H

#include "ae_effect.h"

namespace mammon {

    class OnlineLoudNorm : public Effect {
    public:
        static constexpr const char* EFFECT_NAME = "online_loudnorm";

        OnlineLoudNorm(int num_channels, int sample_rate);
        virtual ~OnlineLoudNorm() = default;

        const char* getName() const override {
            return EFFECT_NAME;
        }

        void setParameter(const std::string& parameter_name, float val) override;

        int process(std::vector<Bus>& bus_array) override;

        void reset() override;

    private:
        DEFINE_PARAMETER(integrated, 0, -120, 120)
        DEFINE_PARAMETER(peak, 1, 0, 1.0)

    private:
        class Impl;
        std::shared_ptr<Impl> impl_;
    };
}  // namespace mammon

#endif  // AUDIO_EFFECT_AE_ONELINE_LOUDNORM_H
