

//
// Created by william on 2019-04-24.
//

#pragma once
#include "ae_effect.h"

namespace mammon {
    class Fading : public Effect {
    public:
        static constexpr const char* EFFECT_NAME = "fading";
        Fading(int sample_rate, int num_channels);

        virtual ~Fading() = default;

        const char* getName() const override {
            return EFFECT_NAME;
        }

        void setParameter(const std::string& parameter_name, float val) override;

        enum FadingCurveType { kLog = 0, kLinear, kExp };

        int process(std::vector<Bus>& bus_array) override;

        void reset() override {
        }

        bool seek(double newPosInSamples, int mode) override;

    private:
        DEF_PARAMETER(duration_, "content_duration", 0)
        DEF_PARAMETER(duration_fadein_, "fade_in_duration", 0)
        DEF_PARAMETER(duration_fadeout_, "fade_out_duration")
        DEF_PARAMETER(curve_fadein_, "curve_fadein", kLog)
        DEF_PARAMETER(curve_fadeout_, "curve_fadeout", kLog)
        DEF_PARAMETER(position_, "position", 0)

    private:
        class Impl;
        std::shared_ptr<Impl> impl_;
    };
}  // namespace mammon
