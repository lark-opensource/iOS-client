//
// Created by william on 2019-04-25.
//

#pragma once
#include "ae_effect.h"
#include "ae_macros.h"

namespace mammon
{
class AudioEffectFilterX : public Effect
{

public:
    enum EffectType
    {
        UNDEF = 0,
        LADY,
        LASSOCK,
        TOMUNCLE,
        GHOST,
        ROBOT
    };

    static constexpr const char* EFFECT_NAME = "effect_filter";
    AudioEffectFilterX(int sample_rate, int num_channel, EffectType type);
    virtual ~AudioEffectFilterX() = default;

    void setParameter(const std::string &parameter_name, float val) override;
    const char* getName() const override {
        return EFFECT_NAME;
    }

    int process(std::vector<Bus>& bus_array) override;

    void reset() override {}
private:
    DEF_PARAMETER(phaseResetMode, "phaseResetMode", 0)
    DEF_PARAMETER(semitone, "semitone", 0)
    DEF_PARAMETER(formatShiftOn, "formatShiftOn", 0)
    DEF_PARAMETER(blockSize, "blockSize", 0)
    DEF_PARAMETER(phaseAdjustMethod, "phaseAdjustMethod", 0)
    DEF_PARAMETER(octave, "octave", 0)
    DEF_PARAMETER(smoothOn, "smoothOn", 0)
    DEF_PARAMETER(centtone, "centtone", 0)
    DEF_PARAMETER(transientDetectMode, "transientDetectMode", 0)
    DEF_PARAMETER(speedRatio, "speedRatio", 0)
    DEF_PARAMETER(windowMode, "windowMode", 0)
    DEF_PARAMETER(pitchTunerMode, "pitchTunerMode", 0)
    DEF_PARAMETER(processChMode, "processChMode", 0)

    class Impl;
    std::shared_ptr<Impl> impl_;

    DISALLOW_COPY_AND_ASSIGN(AudioEffectFilterX);
};
}
