//
// Created by william on 2019-04-15.
//

#pragma once

#include "ae_effect.h"
#include "ae_reverb2_mode.h"

namespace mammon {
    /**
     * @brief Reverb processor
     *
     * @code
     *
     * // set processor
     * Reverb2 processor;
     * processor.setParameter("preset_mode", 3);
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
     */
    class Reverb2 : public Effect {
    public:
        static constexpr const char* EFFECT_NAME = "reverb2";
        /**
         * Creates reverb processor
         * @param sample_rate sample rate of audio to process
         */
        Reverb2(int sample_rate);
        virtual ~Reverb2() = default;

        void setParameter(const std::string& parameter_name, float val) override;
        const char* getName() const override {
            return EFFECT_NAME;
        }

        int process(std::vector<Bus>& bus_array) override;

        void reset() override {
        }

    private:
        /**
         * Present reverb mode
         *
         * Setting present reverb mode will change the other parameters' value.
         *
         * @see ReverbMode
         * */
        DEF_PARAMETER(over_sample_rate_, "over_sample_rate", 1, 1,
                      2) /**< how much to oversample, range:[1, 2], default:0, */
        DEF_PARAMETER(early_ref_amount_, "early_ref_amount", 0.5, 0,
                      1) /**< early reflection amount, range:[0, 1], default:0, */
        DEF_PARAMETER(early_ref_wet_, "early_ref_wet", 0, -70,
                      10)                      /**< dB, final wet mix, range:[-70, 10], default:0, */
        DEF_PARAMETER(dry_, "dry", -70, -70, 10) /**< dB, final dry mix, range:[-70, 10], default:0, */
        DEF_PARAMETER(early_ref_factor_, "early_ref_factor", 1.0, 0.5,
                      2.5) /**< early reflection factor, range:[0.5, 2.5], default:0, */
        DEF_PARAMETER(early_ref_width_, "early_ref_width", 0, -1,
                      1)                                    /**< early reflection width, range:[-1, 1], default:0, */
        DEF_PARAMETER(mix_width_, "mix_width", 0, 0, 1)     /**< width of reverb L/R mix, range:[0, 1], default:0, */
        DEF_PARAMETER(wet_, "wet", 0, -70, 10)              /**< dB, reverb wetness range:[-70 to 10], default:0 */
        DEF_PARAMETER(wander_, "wander", 0.2, 0.1, 0.6)     /**< LFO wander amount range:[0.1 to 0.6],default:0 */
        DEF_PARAMETER(bass_boost_, "bass_boost", 0, 0, 0.5) /**< bass boost range:[0 to 0.5], default:0 */
        DEF_PARAMETER(spin_, "spin", 0, 0, 10)              /**< LFO spin amount range:[0 to 10], default:0 */
        DEF_PARAMETER(input_lowpass_cutoff_, "input_lowpass_cutoff", 250, 200,
                      18000) /**< Hz, lowpass cutoff for input range:[200 to 18000],default:0 */
        DEF_PARAMETER(bass_lowpass_cutoff_, "bass_lowpass_cutoff", 250, 50,
                      1050) /**< Hz, lowpass cutoff for bass range:[50 to 1050], default:0 */
        DEF_PARAMETER(damp_lowpass_cutoff_, "damp_lowpass_cutoff", 250, 200,
                      18000) /**< Hz, lowpass cutoff for dampening [200 to 18000] */
        DEF_PARAMETER(output_lowpass_cutoff_, "output_lowpass_cutoff", 250, 200,
                      18000)                                     /**< Hz, lowpass cutoff for output [200 to 18000] */
        DEF_PARAMETER(reverb_time_, "reverb_time", 2, 0.1, 30) /**< reverb time decay range:[0.1 to 30], default:0*/
        DEF_PARAMETER(delay_, "delay", 1, -0.5, 0.5)             /**< seconds, amount of delay [-0.5 to 0.5] */

    private:
        class Impl;
        std::shared_ptr<Impl> impl_;
    };

}  // namespace mammon
