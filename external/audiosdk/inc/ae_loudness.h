//
// Created by william on 2019-04-19.
//

#pragma once

#include "ae_effect.h"

namespace mammon {
    /**
     * This processor makes the audio louder
     *
     * @code
     *
     * // set processor
     * LoudnessProcessor processor;
     * processor.setParameter("adjust_gain", 0.5);
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
     *
     * @see Bus
     * @see Effect
     */
    class LoudnessProcessor : public Effect {
    public:
        /**
         * Enhance the perceived volume with sin modulation algorithm,
         */
        enum ClipMode {
            ENHANCE_NO_CLIP = 0,  /**< this algorithm won't clip by itself. */
            REDUCE_SCALE_NO_CLIP, /**< reduce the gain change to avoid clipping where necessary, THIS REQUIRES the peak
                                     detector to have been run.*/
            SOFT_CLIP,            /**< do the gain change and use soft clipping where necessary */
            SOFT_CLIP_WITH_LIMITER, /**< do the gain change and use a limiter and soft clipping where necessary*/
            HARD_CLIP               /**< do the gain scale and hard clip. */
        };

        static constexpr const char* EFFECT_NAME = "loudness";
        LoudnessProcessor(int sample_rate, int num_channels);
        virtual ~LoudnessProcessor() = default;

        const char* getName() const override {
            return EFFECT_NAME;
        }

        void setParameter(const std::string& parameter_name, float val) override;

        virtual int process(std::vector<Bus>& bus_array) override;

        void reset() override {
        }

    private:
        /**
         * Sets clip mode.
         *
         * @see ClipMode
         */
        DEF_PARAMETER(clip_mode_, "clip_mode", static_cast<float>(ENHANCE_NO_CLIP), static_cast<float>(ENHANCE_NO_CLIP),
                      static_cast<float>(HARD_CLIP))
        /**
         * The gain adjusted
         */
        DEF_PARAMETER(adjust_gain_, "adjust_gain", 0.0, 0.0, 1.0)
        /**
         * This parameter will non-linear compress the audio to make it sound louder. The range will be in [0, 0.1].
         * @note 0 will also make the audio sound louder. Larger value will make it much lounder.
         */
        DEF_PARAMETER(constrast_, "contrast", 0.0, 0, 0.1)

        /**
         * If provided(PeakAnalysis has been run before calling this)
         */
        DEF_PARAMETER(peak_, "peak", 1.0f, 0.0, 1.0)
        /**
         * The RMS level(in dBFS) that limiter use to ensure it's never get exceeded. Default is set to -5.0 dBFS
         */
        DEF_PARAMETER(RMSMaxdB_, "RMSMax", -5.0f, -20, 10)
        /**
         * The attack time for the limiter in seconds. Default is set to 40.1642ms.
         */
        DEF_PARAMETER(attack_time_, "attack_time", 0.0401642f, 0, 1.0)
        /**
         * The releae time for the limiter in seconds. Default is set to 743.039ms.
         */
        DEF_PARAMETER(release_time_, "release_time", 0.743039f, 0, 1.0)

    private:
        class Impl;
        std::shared_ptr<Impl> impl_;
    };

}  // namespace mammon
