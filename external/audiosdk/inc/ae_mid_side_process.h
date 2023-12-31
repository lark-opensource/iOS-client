//
// Created by william on 2019-04-15.
//

#pragma once
#include "ae_effect.h"
#include "ae_parameter.h"

namespace mammon {
    /**
     * @brief Mide and side process
     *
     * This technique gives you more control over the width of the stereo spread. The input audio must be stereo.
     *
     * 这个技术能够增加声音的声场，输入的音频必须是双声道
     *
     * @code
     * // set processor
     * MidSideProcess processor;
     * processor.setParameter("weight_id", 3);
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
    class MidSideProcess : public Effect {
    public:
        static constexpr const char* EFFECT_NAME = "stereo_widen";

        MidSideProcess();
        virtual ~MidSideProcess() = default;

        const char* getName() const override {
            return EFFECT_NAME;
        }

        void setParameter(const std::string& parameter_name, float val) override;

        int process(std::vector<Bus>& bus_array) override;

        void reset() override {
        }

    private:
        /**
         * Preset mode, range:[-1, 4], default:-1. -1 means no MS process, 0~4 MS effect enhanced in turn.
         */
        DEF_PARAMETER(weight_id_, "weight_id", -1, -1, 4)

    private:
        class Impl;
        std::shared_ptr<Impl> impl_;
    };
}  // namespace mammon
