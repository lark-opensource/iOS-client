//
// Created by william on 2019-06-05.
//

#pragma once
#include "ae_effect.h"

namespace mammon {
    class Reverb1 : public Effect {
    public:
        static constexpr const char* EFFECT_NAME = "reverb1";

        Reverb1(int sample_rate, int num_channels);
        virtual ~Reverb1() = default;

        const char* getName() const override {
            return EFFECT_NAME;
        }

        void setParameter(const std::string& parameter_name, float val) override;

        int process(std::vector<Bus>& bus_array) override;

        void reset() override {
        }

    private:
        DEF_PARAMETER(room_size_, "room_size", 0.5, 0.0, 1.5)
        DEF_PARAMETER(damping_, "damping", 0.5, 0.0, 0.9)
        DEF_PARAMETER(stereo_depth_, "stereo_depth", 0.5, 0.0, 1.0)
        DEF_PARAMETER(dry_, "dry", 0.5, 0.0, 1.0)
        DEF_PARAMETER(wet_, "wet", 0.5, 0.0, 1.0)
        DEF_PARAMETER(dry_gaindB_, "dry_gaindB", 0.5, 0.0, 1.0)
        DEF_PARAMETER(wet_gaindB_, "wet_gaindB", 0.5, 0.0, 1.0)
        DEF_PARAMETER(dry_only_, "dry_only", static_cast<float>(false), 0, 1)
        DEF_PARAMETER(wet_only_, "wet_only", static_cast<float>(false), 0, 1)

        class Impl;
        std::shared_ptr<Impl> impl_;
    };

}  // namespace mammon