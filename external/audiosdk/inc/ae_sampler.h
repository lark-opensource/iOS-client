//
// Created by Feng Suiyu on 2020-02-10.
//

#pragma once
#include "ae_effect.h"

namespace mammon {
    /**
     * A Sampler
     *
     * @code
     *
     * // set processor
     * SamplerX processor;
     * processor.setParameter("id", 1); // will load "1.wav"
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
    class SamplerX : public Effect {
    public:
        static constexpr const char* EFFECT_NAME = "sampler";

        SamplerX(int num_channels, int sample_rate);
        virtual ~SamplerX() = default;

        const char* getName() const override {
            return EFFECT_NAME;
        }

        void setParameter(const std::string& parameter_name, float val) override;

        int process(std::vector<Bus>& bus_array) override;

        void reset() override;

        bool seek(double newPosInSec, int mode = SEEK_SET) override;
        bool seek(int64_t newPosInSamples, int mode = SEEK_SET) override;
        void seekDefinitely(int64_t newPosInSamples) override;

    private:
        DEFINE_PARAMETER(id, 0, -99999, 99999)
        DEFINE_PARAMETER(dry, 1, 0, 1)
        DEFINE_PARAMETER(wet, 1, 0, 1)
        DEFINE_PARAMETER(start, 0, 0, 24 * 60 * 60)
        DEFINE_PARAMETER(loopStart, 0, 0, 24 * 60 * 60)
        DEFINE_PARAMETER(loopEnd, 0, -1, 24 * 60 * 60)

        DEFINE_PARAMETER(minLoopTimes, 0, -1, 99999)
        DEFINE_PARAMETER(maxLoopTimes, 0, 0, 99999)
        DEFINE_PARAMETER(minRepeatDelay, 0, -1, 24 * 60 * 60)
        DEFINE_PARAMETER(maxRepeatDelay, 0, 0, 24 * 60 * 60)
        DEFINE_PARAMETER(minPreDelay, 0, 0, 24 * 60 * 60)
        DEFINE_PARAMETER(maxPreDelay, 0, 0, 24 * 60 * 60)

    private:
        class Impl;
        std::shared_ptr<Impl> impl_;
    };
}  // namespace mammon
