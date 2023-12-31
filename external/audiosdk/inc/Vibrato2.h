//
// Created by chenyuezhao on 2019/2/28.
//
#pragma once

#include "LFOscillator.h"
#include "ae_defs.h"

namespace mammon {

    class MAMMON_DEPRECATED Vibrato2 {
    public:
        static constexpr float MAX_SEMITONES_NUM = 64;

    public:
        /* rate: 1 <0, 100, 0.01> LFO频率
         * waveform: Sinusoidal <{WAVEFORM}> one of WAVEFORM
         * semitones: 3 <0, MAX_SEMITONES_NUM, 0.01> how many semitones the pitch variation around
         */
        Vibrato2(int samplerate, float rate, float semitones,
                 LFOscillator::WAVEFORM waveform = LFOscillator::Sinusoidal);
        ~Vibrato2();
        void setOscillator(float rate, float semitones, LFOscillator::WAVEFORM waveform = LFOscillator::Sinusoidal);

        void process(float in, float* out);

    private:
        LFOscillator::WAVEFORM waveform;
        LFOscillator* oscillator;

        int buf_size;
        float* buf;
        int write_index;
    };

}  // namespace mammon
