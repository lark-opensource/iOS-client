//
// Created by chenyuezhao on 2019/3/1.
//
#include "ae_defs.h"

#pragma once
namespace mammon {
    class MAMMON_EXPORT LFOscillator {
    public:
        enum WAVEFORM { Sinusoidal, Triangle };

        static LFOscillator* getInstance(WAVEFORM waveform, int samplerate, float freq, float ratio);

    public:
        LFOscillator(int samplerate, float f, float ratio);

        virtual ~LFOscillator(){};

        virtual float nextNumberOfDelayedSamples() = 0;

        virtual float maxNumberOfDelayedSamples() = 0;

        int getSampleRate();

        float getFreq();

        float getRatio();

    private:
        int samplerate;
        float f;
        float ratio;
    };
}  // namespace mammon
