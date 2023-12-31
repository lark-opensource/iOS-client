//
// Created by william on 2019-04-25.
//

#pragma once

#include "ae_effect.h"

namespace mammon {

    enum TransformType {
        MDCT_320X18 = 0,
        MDFT_512X320X18,  // Identifiers for supported types
        MDFT_512X320X36,
        MDFT_512X384X36,
        MDFT_256X56X24,
        MDFT_32X32X12
    };

    /**
     * Clean up audio signal
     */

    class AudioCleanerX : public Effect {
    public:
        static constexpr const char* EFFECT_NAME = "cleaner";

        AudioCleanerX(int sample_rate, int channel_num);
        virtual ~AudioCleanerX() = default;

        const char* getName() const override {
            return EFFECT_NAME;
        }

        void setParameter(const std::string& parameter_name, float val) override;

        size_t getRequiredBlockSize() const override;

        int process(std::vector<Bus>& bus_array) override;

        void reset() override {
        }

    private:
        /**
         * Transform type
         * @see TransformType
         */
        DEF_PARAMETER(transform_type_, "transform_type", TransformType::MDFT_512X384X36, 0, 5)
        /**
         * Enable music mode
         */
        DEF_PARAMETER(music_mode_, "music_mode", static_cast<float>(true), 0, 1)
        /**
         * Enable the AGC and the AGCGain is default 4.0
         */
        DEF_PARAMETER(AGC_mode_, "AGC_mode", static_cast<float>(true), 0, 1)
        /**
         * Enable the noise reduction
         */
        DEF_PARAMETER(ANS_mode_, "ANS_mode", static_cast<float>(true), 0, 1)
        /**
         * Enable the echo suppression
         */
        DEF_PARAMETER(AEC_mode_, "AEC_mode", static_cast<float>(false), 0, 1)
        /**
         * Enable limiter
         * @see Limiter
         */
        DEF_PARAMETER(limiter_mode_, "limiter_mode", static_cast<float>(true), 0, 1)
        /**
         * Enable high noise mode(reduced talk sensitivity)
         */
        DEF_PARAMETER(high_noise_mode_, "high_noise_mode", static_cast<float>(false), 0, 1)
        /**
         * Enable spatial noise reduction
         */
        DEF_PARAMETER(beam_mode_, "beam_mode", static_cast<float>(false), 0, 1)

    private:
        class Impl;
        std::shared_ptr<Impl> impl_;
    };
}  // namespace mammon
