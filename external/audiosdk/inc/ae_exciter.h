//
// Created by william on 2019-04-24.
//

#pragma once
#include "ae_effect.h"

namespace mammon {
    /**
     * Exciter used to enhance a signal
     *
     * @code
     *
     * // set processor
     * ExciterX processor;
     * processor.setParameter("mix_gain", 6.0);
     * processor.setParameter("high_pass_freq", 1000.0);
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
     * @see Bus
     * @see Effect
     */
    class ExciterX : public Effect {
    public:
        static constexpr const char* EFFECT_NAME = "exciter";
        ExciterX(int sample_rate);
        virtual ~ExciterX() = default;

        const char* getName() const override {
            return EFFECT_NAME;
        }

        void setParameter(const std::string& parameter_name, float val) override;

        int process(std::vector<Bus>& bus_array) override;

        void reset() override {
        }

    private:
        /**
         * mix gain of the hamonic signal, [-100, 12] in dB, defalut 0.0 dB
         */
        DEF_PARAMETER(mixgaindB_, "mix_gain", 0, -100, 12)
        /**
         * cut-off frequency for the high pass filter when generating the homonic component, [100, sampling rate],
         * default 1000 Hz
         */
        DEF_PARAMETER(high_pass_freq_, "high_pass_freq", 1000, 100, 48000)

        class Impl;
        std::shared_ptr<Impl> impl_;
    };
}  // namespace mammon
