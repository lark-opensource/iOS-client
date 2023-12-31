//
// Created by william on 2019-04-22.
//

#pragma once
#include "ae_effect.h"

namespace mammon {
    /**
     * A multi-channel limiter
     * Method: low pass filter the absolute value of each channel and find the maximum over
     * all these channels and then use the reciprocal of maximum for the gain.
     *
     * @code
     * // set processor
     * Limiter processor;
     * processor.setParameter("gain_", 1.2);
     * processor.setParameter("RMSMax", 0.56);
     *
     * // create bus to process
     * int num_bus = 1;
     * vector<Bus> bus_array(num_bus);
     * float* data_refer_to[2] = {left_channel, right_channel};
     * bus_array[0] = Bus("master", data_refert_to, 2, num_samples);
     *
     * // process
     * processor.process(bus_array);
     * @endcode
     */
    class LimiterX : public Effect {
    public:
        static constexpr const char* EFFECT_NAME = "limiter";
        LimiterX(int sample_rate, int num_channels);
        virtual ~LimiterX() = default;

        const char* getName() const override {
            return EFFECT_NAME;
        }

        void setParameter(const std::string& parameter_name, float val) override;

        int process(std::vector<Bus>& bus_array) override;

        void reset() override {
        }

    private:
        /**
         * gain, the signal (when small) just gets multiplied by this value
         */
        DEF_PARAMETER(gain_, "gain", 1.0f, 0.0, 1.0)
        /**
         * the signal is limited to below this value.
         */
        DEF_PARAMETER(RMSMax_, "RMSMax", 0.0, 0.0, 1.0)
        /**
         * the attack time in seconds
         */
        DEF_PARAMETER(attack_time_, "attack_time", 0.0401642f, 0, 1.0)
        /**
         * the release time in seconds.
         */
        DEF_PARAMETER(release_time_, "release_time", 0.743039f, 0, 1.0)

    private:
        class Impl;
        std::shared_ptr<Impl> impl_;
    };

}  // namespace mammon
