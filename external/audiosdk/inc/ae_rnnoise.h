//
//  ae_rnnoise.hpp
//  IESAudioEffect
//
//  Created by tangshi on 2019/6/5.
//

#pragma once

#include "ae_effect.h"

namespace mammon {

    class RNNoise : public Effect {
    public:
        static constexpr const char* EFFECT_NAME = "rnnoise";

        RNNoise(int sample_rate, int channels, int threads = 1);
        virtual ~RNNoise() = default;

        size_t getRequiredBlockSize() const override;

        size_t getLatency() const override;

        const char* getName() const override {
            return EFFECT_NAME;
        }

        void setParameter(const std::string& parameter_name, float val) override;

        virtual int process(std::vector<Bus>& bus_array) override;

        void reset() override {
        }

        std::string getModelVersion() const override;

        void loadModel(std::shared_ptr<uint8_t>& buf, size_t) override;
        void loadModel(const uint8_t* buf, size_t size) override;

    private:
        DEF_PARAMETER(denoisemode_, "denoisemode", 0, 0, 1)
        class Impl;
        std::shared_ptr<Impl> impl_;
    };

}  // namespace mammon
