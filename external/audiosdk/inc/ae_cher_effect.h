//
// Created by william on 2019-04-26.
//

#pragma once

#include "ae_effect.h"

namespace mammon {
    class ChertEffectX : public Effect {
    public:
        static constexpr const char* EFFECT_NAME = "cher";
        ChertEffectX(int sample_rate, int num_channel, bool is_mix);
        virtual ~ChertEffectX() = default;

        void setParameter(const std::string& parameter_name, float val) override;

        virtual void setPreprocessing(bool on) override;
        const char* getName() const override {
            return EFFECT_NAME;
        }

        bool needsPreprocess() override;

        enum MajorType {
            kMajorNA = 0,
            kMajorC,
            kMajorDb,
            kMajorD,
            kMajorEb,
            kMajorE,
            kMajorF,
            kMajorGb,
            kMajorG,
            kMajorAb,
            kMajorA,
            kMajorBb,
            kMajorB
        };

        enum ParameterType { kMajor = 0, kSeekPoistion };

        int process(std::vector<Bus>& bus_array) override;

        void reset() override {
        }

    private:
        DEF_PARAMETER(major_, "major", static_cast<float>(MajorType::kMajorC), 0, 12)
        DEF_PARAMETER(seek_position_, "seek_position", 0)
    private:
        class Impl;
        std::shared_ptr<Impl> impl_;
    };
}  // namespace mammon
