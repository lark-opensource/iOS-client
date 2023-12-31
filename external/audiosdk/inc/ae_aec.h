//
// Created by william on 2019-04-25.
//

#pragma once

#include "ae_effect.h"

namespace mammon {

    static const char* aec_model_name = "aec_v1.0.model";
    static const char* aec_44k_model_name = "aec44k_v1.0.model";

    class AEC : public Effect {
    public:
        static constexpr const char* EFFECT_NAME = "aec";

        explicit AEC(int sample_rate);
        virtual ~AEC() = default;

        const char* getName() const override;
        size_t getRequiredBlockSize() const override;

        size_t getLatency() const override;

        size_t getTimeDelay() const;
        float getMixVolume() const;

        int setMode(int mode);

        int process(std::vector<Bus>& bus_array) override;
        void reset() override {
        }

        int getInputBusesCount() const override;

    private:
        class Impl;
        std::shared_ptr<Impl> impl_;
    };

    class AecMicSelection : public Effect {
    public:
        static constexpr const char* EFFECT_NAME = "aec_mic_selection";

        explicit AecMicSelection(int samplerate, int channels);
        virtual ~AecMicSelection() = default;

        const char* getName() const override;
        size_t getRequiredBlockSize() const override;
        size_t getLatency() const override;
        void setParameter(const std::string& parameter_name, float val) override;
        int process(std::vector<Bus>& bus_array) override;
        void reset() override;

        size_t getTimeDelay() const;

        void loadModel(std::shared_ptr<uint8_t>& buf, size_t size) override;
        void loadModel(const uint8_t* buf, size_t size) override;

        int getInputBusesCount() const override;

    private:
        DEF_PARAMETER(nlp_mode_, "nlp_mode", 0, 0, 2)

        class AecMicSelectionImpl;
        std::shared_ptr<AecMicSelectionImpl> impl_;
    };

}  // namespace mammon
