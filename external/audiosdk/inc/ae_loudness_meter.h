//
// Created by william on 2019-04-22.
//

#pragma once
#include "ae_effect.h"

namespace mammon {

    class LoudnessMeterX : public Effect {
    public:
        static constexpr const char* EFFECT_NAME = "loudness_meter";

        LoudnessMeterX(int num_channels, int sample_rate);
        virtual ~LoudnessMeterX() = default;

        const char* getName() const override {
            return EFFECT_NAME;
        }

        void setParameter(const std::string& parameter_name, float val) override;

        int process(std::vector<Bus>& bus_array) override;

        void reset() override;

        int process(float* audio_buffer, int num_channel, int channel_sample, bool is_interleave);
        int process(float** audio_buffer, int num_channel, int channel_sample, bool is_interleave);

    private:
        DEFINE_PARAMETER(integrated, 0, -120, 120)
        DEFINE_PARAMETER(peak, 1, 0, 1.0)

        DEFINE_PARAMETER(shortterm, 2, -120, 120)
        DEFINE_PARAMETER(momentary, 3, -120, 120)
        DEFINE_PARAMETER(relativethreshold, 4, -120, 120)

        DEFINE_PARAMETER(maxmomentaryloudness, 5, -120, 120)
        DEFINE_PARAMETER(maxshorttermloudness, 6, -120, 120)
        DEFINE_PARAMETER(loudnessrange, 7, -120, 120)
        DEFINE_PARAMETER(loudnessrangestart, 8, -120, 120)
        DEFINE_PARAMETER(loudnessrangeend, 9, -120, 120)

    private:
        class Impl;
        std::shared_ptr<Impl> impl_;
    };
}  // namespace mammon
