//
// Created by william on 2019/9/22.
//

#pragma once
#include "ae_effect.h"
#include "ae_macros.h"

namespace mammon {
    class MAMMON_EXPORT VolumeDetector : public Effect {
    public:
        static constexpr const char* EFFECT_NAME = "volume_detection";

        explicit VolumeDetector(int sample_rate);

        const char* getName() const override {
            return EFFECT_NAME;
        }

        int process(std::vector<Bus>& bus_array) override;

        const std::vector<std::pair<float, float>>& getDetectedResult() const;

        void reset() override {
        }

    private:
        class Impl;
        std::shared_ptr<Impl> impl_;
        DISALLOW_COPY_AND_ASSIGN(VolumeDetector);
    };

}  // namespace mammon
