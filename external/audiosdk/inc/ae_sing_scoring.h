//
// Created by william on 2019-04-26.
//

#pragma once

#include <string>
#include "SingScoring.h"
#include "ae_effect.h"

namespace mammon {
    class SingScoringX : public Effect {
    public:
        SingScoringX(int sample_rate, int num_channels, const std::string& midi_file, const std::string& lyric_file);

        virtual ~SingScoringX() = default;

        const char* getName() const override {
            return "singscoring";
        }

        DEFINE_PARAMETER(method, 0, 0, 3)

        void setParameter(const std::string& parameter_name, float val) override;

        void getRealTimeInfo(SingScoring::RealtimeInfo& info) const;

        int process(std::vector<Bus>& bus_array) override;

        void reset() override {
        }

    private:
        class Impl;
        std::shared_ptr<Impl> impl_;
    };
}  // namespace mammon