//
// Created by Shi on 2019/9/20.
//

#ifndef AUDIO_EFFECT_AE_STEREO_PANNING_H
#define AUDIO_EFFECT_AE_STEREO_PANNING_H

#include "ae_effect.h"
#include "ae_parameter.h"

namespace mammon {

    class StereoPanning : public Effect {
    public:
        static constexpr const char* EFFECT_NAME = "stereo_panning";
        // TODO: 构造函数加入声道数判定逻辑
        StereoPanning();

        virtual ~StereoPanning() = default;

        const char* getName() const override {
            return EFFECT_NAME;
        }

        void setParameter(const std::string& parameter_name, float val) override;

        int getSourcePosition(int source_id, float& x, float& y, float& z);

        int getSourceAngle(int source_id, float& azimuth, float& elevation);

        int getStereoPanningGains(int source_id, float& l_gain, float& r_gain);

        int process(std::vector<Bus>& bus_array) override;

        void reset() override {
        }

    private:
        //        DEF_PARAMETER(x_, "x", 1, std::numeric_limits<float>::lowest(), std::numeric_limits<float>::max());
        //        DEF_PARAMETER(y_, "y", 0, std::numeric_limits<float>::lowest(), std::numeric_limits<float>::max());
        //        DEF_PARAMETER(z_, "z", 0, std::numeric_limits<float>::lowest(), std::numeric_limits<float>::max());
        // TODO: 确认初始化参数
        DEF_PARAMETER(x_, "x", 1, -5, 5)
        DEF_PARAMETER(y_, "y", 0, -5, 5)
        DEF_PARAMETER(z_, "z", 0, -5, 5)
        DEF_PARAMETER(source_id_, "source_id", 0, 0, 31)
        DEF_PARAMETER(wet_gain_, "wet_gain", 1.0, 0.0, 1.0)
        DEF_PARAMETER(update_, "update", 1.0, 0.0, 1.0)

        class Impl;

        std::shared_ptr<Impl> impl_;

        const int kIdMax = 31;
        const int kIdMin = 0;
    };

}  // namespace mammon

#endif  // AUDIO_EFFECT_AE_STEREO_PANNING_H
