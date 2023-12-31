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
    class EqualizerX : public Effect {
    public:
        static constexpr const char* EFFECT_NAME = "eq";

        EqualizerX(int sample_rate, int num_channels);
        virtual ~EqualizerX() = default;

        const char* getName() const override {
            return EFFECT_NAME;
        }

        void setParameter(const std::string& parameter_name, float val) override;

        int process(std::vector<Bus>& bus_array) override;

        void reset() override;

    private:
        DEF_PARAMETER(pass_eq_, "is_pass_eq", static_cast<float>(false), 0, 1) /**< pass equalizer filter*/

        DEF_PARAMETER(pre_amplitude_gain_, "pre_amplitude_gain", 0, -18, 18)

        DEF_PARAMETER(gain0_, "gain0", 0, -18, 18)
        DEF_PARAMETER(gain1_, "gain1", 0, -18, 18)
        DEF_PARAMETER(gain2_, "gain2", 0, -18, 18)
        DEF_PARAMETER(gain3_, "gain3", 0, -18, 18)
        DEF_PARAMETER(gain4_, "gain4", 0, -18, 18)
        DEF_PARAMETER(gain5_, "gain5", 0, -18, 18)
        DEF_PARAMETER(gain6_, "gain6", 0, -18, 18)
        DEF_PARAMETER(gain7_, "gain7", 0, -18, 18)
        DEF_PARAMETER(gain8_, "gain8", 0, -18, 18)
        DEF_PARAMETER(gain9_, "gain9", 0, -18, 18)

        DEF_PARAMETER(width0_, "width0", 1, 0, 1)
        DEF_PARAMETER(width1_, "width1", 1, 0, 1)
        DEF_PARAMETER(width2_, "width2", 1, 0, 1)
        DEF_PARAMETER(width3_, "width3", 1, 0, 1)
        DEF_PARAMETER(width4_, "width4", 1, 0, 1)
        DEF_PARAMETER(width5_, "width5", 1, 0, 1)
        DEF_PARAMETER(width6_, "width6", 1, 0, 1)
        DEF_PARAMETER(width7_, "width7", 1, 0, 1)
        DEF_PARAMETER(width8_, "width8", 1, 0, 1)
        DEF_PARAMETER(width9_, "width9", 1, 0, 1)

    private:
        class Impl;
        std::shared_ptr<Impl> impl_;
    };

    /*
     * Parametric Equalizer
     */
    class EqualizerParametricX : public Effect {
    public:
        static constexpr const char* EFFECT_NAME = "parametric_eq";

        EqualizerParametricX(int samplerate, int channels);
        virtual ~EqualizerParametricX() = default;

        const char* getName() const override {
            return EFFECT_NAME;
        }

        void setParameter(const std::string& parameter_name, float val) override;

        void setParameters(const std::map<std::string, float>& parameters) override;

        /*
         * vec[0]: type
         * vec[1]: fc
         * vec[2]: gain
         * vec[3]: q
         */
        const std::vector<std::vector<float>> getParameters();

        int process(std::vector<Bus>& bus_array) override;

        void reset() override;

    private:
        DEF_PARAMETER(pre_gain_, "pre_gain", 0, -18, 18)
        DEF_PARAMETER(bands_, "num_bands", 5, 0, 64)

        class Impl;
        std::shared_ptr<Impl> impl_;
    };

}  // namespace mammon
