//
// Created by william on 2019-04-22.
//

#pragma once
#include "ae_effect.h"

namespace mammon {
    /**
     * A Equalizer
     *
     * @code
     *
     * // set processor
     * EqualizerX processor;
     * processor.setParameter("preset_id", 5);
     *
     * // create bus to process
     * int num_bus = 1;
     * vector<Bus> bus_array(num_bus);
     * float* data_refer_to[2] = {left_channel, right_channel};
     * bus_array[0] = Bus("master", data_refert_to, 2, num_samples);
     *
     * // process
     * processor.process(bus_array);
     *
     * @endcode
     */
    class HQFaderX : public Effect {
    public:
        static constexpr const char* EFFECT_NAME = "hq_fader";

        HQFaderX(int num_channels, int sample_rate);
        virtual ~HQFaderX() = default;

        const char* getName() const override {
            return EFFECT_NAME;
        }

        void setParameter(const std::string& parameter_name, float val) override;

        int process(std::vector<Bus>& bus_array) override;

        void reset() override;

    private:
        DEFINE_PARAMETER(peak, 0, 0, 1.0)
        DEFINE_PARAMETER(hardLimit, 1, 0, 1)
        DEFINE_PARAMETER(targetLoudness, -22, -30, 0)
        DEFINE_PARAMETER(loudness, -9, -90, 12)
        DEFINE_PARAMETER(volume, 1, 0, 1)
        DEFINE_PARAMETER(on, 1, 0, 1)
        DEFINE_PARAMETER(normalizedToTargetLoudness, 1, 0, 1)
        DEFINE_PARAMETER(normalizedToPeak, 0, 0, 1)

    private:
        class Impl;
        std::shared_ptr<Impl> impl_;
    };
}  // namespace mammon
