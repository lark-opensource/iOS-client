//
// Created by william on 2019-05-21.
//

#pragma once
#include <memory>
#include "ae_defs.h"
#include "ae_effect.h"
#include "ae_nrt_effect.h"

namespace mammon {

    class EffectFactory {
    public:
        virtual std::unique_ptr<mammon::Effect> create(int sample_rate, int num_channel) = 0;
        virtual std::unique_ptr<mammon::Effect> create(int sample_rate, int num_channel,
                                                       const std::vector<Parameter>& parameters);
        virtual ~EffectFactory() = default;
    };

    /**
     * @brief Non-realtime effect factory class
     * This interface is used to create non-realtime class, it will be created by a template function.
     */
    class MAMMON_EXPORT NonRealtimeEffectFactory {
    public:
        /**
         * @brief Create a non-realtime effect instance
         * Return nullptr when failed to create a factory
         * @param sample_rate Sampling rate
         * @param num_channel The number of channels
         * @return std::unique_ptr<mammon::NonRealtimeEffect>
         */
        virtual std::unique_ptr<mammon::NonRealtimeEffect> create(int sample_rate, int num_channel) = 0;
        virtual ~NonRealtimeEffectFactory() = default;
    };

    /**
     * @brief Dummy factory
     * Only used for testing logic
     */
    class MAMMON_EXPORT NonRealtimeDummyFactory : public NonRealtimeEffectFactory {
    public:
        std::unique_ptr<mammon::NonRealtimeEffect> create(int sample_rate, int num_channel) final {
            return nullptr;
        }
    };

#ifndef CLOSE_PITCH_SHIFTER
        /**
     * @brief The factory used for creating a non-realtime pitchshifter
     */
    class MAMMON_EXPORT NonRealtimePitchShifterFactory : public NonRealtimeEffectFactory {
    public:
        std::unique_ptr<mammon::NonRealtimeEffect> create(int sample_rate, int num_channel) final;
    };
#endif

    /**
     * @brief The factory used for creating a non-realtime timescaler
     */
    class MAMMON_EXPORT NonRealtimeTimeScalerFactory : public NonRealtimeEffectFactory {
    public:
        std::unique_ptr<mammon::NonRealtimeEffect> create(int sample_rate, int num_channel) final;
    };

}  // namespace mammon
