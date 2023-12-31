//
// Created by william on 2019-06-16.
//

#pragma once
#include "ae_aec.h"

namespace mammon {

    class AECM : public Effect {
    public:
        static constexpr const char* EFFECT_NAME = "aecm";

        explicit AECM(int sample_rate);
        virtual ~AECM() = default;

        const char* getName() const override {
            return EFFECT_NAME;
        };

        int process(std::vector<Bus>& bus_array) override {
            return 0;
        };

        void reset() override {
        }

    private:
        class Impl;
        std::shared_ptr<Impl> impl_;
    };

}  // namespace mammon
