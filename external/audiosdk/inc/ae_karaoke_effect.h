//
// Created by shangchuxiang on 2020-02-27.
//

#pragma once
#include "ae_effect.h"

namespace mammon {

    /*
     * Support two Karaoke Pipeline
     * 1. default:
     *   initialize:
     *      KaraokeEffect(int sample_rate, int num_channel);
     *      or
     *      KaraokeEffect(int sample_rate, int num_channel, "default");
     *   Activated audio effect names:
     *      aec_mic_selection
     *      noise_suppression(default bypassed)
     *      agc
     *      compressor
     *      climiter
     *      loudness_meter
     *
     * 2. live_karaoke:
     *   initialize:
     *      KaraokeEffect(int sample_rate, int num_channel, "live_karaoke");
     *   Activated audio effect names:
     *      aec_mic_selection
     *      noise_suppression(default bypassed)
     *      agc
     *      rnnoise
     *      compressor
     *      climiter
     *      loudness_meter
     *
     * In order to turn off certain module, use setModuleBypassed;
     * egs:
     * processor->setModuleBypassed("aec_mic_selection", true);
     * processor->setModuleBypassed("noise_suppression", true);
     * processor->setModuleBypassed("agc", true);
     * processor->setModuleBypassed("rnnoise", true);
     * processor->setModuleBypassed("compressor", true);
     * processor->setModuleBypassed("climiter", true);
     * processor->setModuleBypassed("loudness_meter", true);
     *
     * In order to turn on certain module, use setModuleBypassed;
     * egs:
     * processor->setModuleBypassed("aec_mic_selection", false);
     * processor->setModuleBypassed("noise_suppression", false);
     * processor->setModuleBypassed("agc", false);
     * processor->setModuleBypassed("rnnoise", false);
     * processor->setModuleBypassed("compressor", false);
     * processor->setModuleBypassed("climiter", false);
     * processor->setModuleBypassed("loudness_meter", false);
     */
    class KaraokeEffect : public Effect {
    public:
        static constexpr const char* EFFECT_NAME = "karaoke";

        KaraokeEffect(int sample_rate, int num_channel);
        KaraokeEffect(int sample_rate, int num_channel, const std::string& preset_name);
        ~KaraokeEffect() = default;

        int process(std::vector<Bus>& bus_array) override;
        void setParameterFromFile(const char* filename);
        void setParameterFromString(const char* effect_yaml_txt);
        size_t getLatency() const override;
        void reset() override;

        size_t getRequiredBlockSize() const override;
        int getNumberOfEffects() const;
        const char* getName() const override;
        bool getModuleBypassed(const std::string& parameter_name) const;
        void setModuleBypassed(const std::string& parameter_name, bool bypassed);

        float getMasterIntegrated() const;
        float getReferenceIntegrated() const;

        float getSuggestVolumeForMaster() const;
        float getSuggestVolumeForRefer() const;

        std::shared_ptr<Effect> getEffect(const std::string& effect_name) const;

        int getDelayTimeInMs() const;

    private:
        class Impl;
        std::shared_ptr<Impl> impl_;
    };
}  // namespace mammon
