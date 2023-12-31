//
// Created by william on 2019-04-24.
//

#pragma once

#include "ae_effect.h"

namespace mammon {
    /**
     * Dynamic range compressor
     *
     * @code
     * // set processor
     * Compressor processor;
     * processor.setParameter("pre_gain", 10);
     * processor.setParameter("threshold", -10);
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
    class Compressor : public Effect {
    public:
        static constexpr const char* EFFECT_NAME = "compressor";
        Compressor(int sample_rate);
        virtual ~Compressor() = default;

        const char* getName() const override {
            return EFFECT_NAME;
        }

        size_t getLatency() const override;

        void setParameter(const std::string& parameter_name, float val) override;

        virtual int process(std::vector<Bus>& bus_array) override;

        void reset() override {
        }

    private:
        DEF_PARAMETER(pre_gain_, "pre_gain", 0, 0,
                      100) /**< dB, amount to boost the signal before applying compression [0 to 100] */
        DEF_PARAMETER(threshold_, "threshold", -24, -100, 0) /**< dB, level where compression kicks in [-20 to 0] */
        DEF_PARAMETER(knee_, "knee", 30, 0, 40)              /**< dB, width of the knee [0 to 40] */
        DEF_PARAMETER(ratio_, "ratio", 12, 1,
                      20) /**< unitless, amount to inversely scale the output when applying comp [1 to 20] */
        DEF_PARAMETER(attack_, "attack", 0.003, 0, 1)  /**< seconds, length of the attack phase [0 to 1] */
        DEF_PARAMETER(release_, "release", 0.25, 0, 1) /**< seconds, length of the release phase [0 to 1] */
        DEF_PARAMETER(pre_delay_, "pre_delay", 0.006, 0,
                      1) /**< seconds; length of the predelay buffer [0 to 1], default 0 */
        DEF_PARAMETER(release_zone_1_, "release_zone_1", 0.09f, 0, 1)
        DEF_PARAMETER(release_zone_2_, "release_zone_2", 0.16f, 0, 1)
        DEF_PARAMETER(release_zone_3_, "release_zone_3", 0.42f, 0, 1)
        DEF_PARAMETER(release_zone_4_, "release_zone_4", 0.98f, 0, 1)
        DEF_PARAMETER(post_gain_, "post_gain", 0, 0,
                      100)                     /**< dB, amount of gain to apply after compression [0 to 100] */
        DEF_PARAMETER(wet_, "wet", 1.0f, 0, 1) /**< amount to apply the effect [0 completely dry to 1 completely wet] */
        DEF_PARAMETER(attenuation_dB_thd_, "attenuation_dB_thd", 2.0, 0,
                      2) /**< (0~2.0)dB, determines the slope of the first part, BAI */
        DEF_PARAMETER(detector_avg_thd_, "detector_avg_thd", 1.0, 0,
                      1) /**< (0~1.0), determines the slope of the second part, BAI */

        class Impl;
        std::shared_ptr<Impl> impl_;
    };
}  // namespace mammon
