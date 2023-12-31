#pragma once
#include <memory>
#include <vector>
#include "ae_defs.h"

namespace mammon {

    class MAMMON_DEPRECATED_EXPORT CLimiter {
    private:
        float mGate, mMax;
        float mGain, mMinGainLP;
        int mBufPos;
        bool mActive;
        int mChannels;
        float mPreGain;  // pre gain, in linear scale

        class Impl;
        std::shared_ptr<Impl> pimpl;

    private:
        static float __inline FloatMax(float v1, float v2) {
            return (v1 > v2) ? v1 : v2;
        }

    public:
        CLimiter();
        ~CLimiter() {
        }

        void SetChannels(int channels);
        void Reset();
        void Process(float** input, float** output, int samplePerChn);
        void Process(float* input, float* output, int samplePerChn);
        float Process(float fSample);
        void FbProcess_mono(float* fSample, float* fSampleOut, int lens);
        void FbProcess_stereo(float* fSampleL, float* fSampleR, float* fSampleOutL, float* fSampleOutR, int lens);
        void SetGate(float fBoundary);
        void SetPreGaindB(float fPreGaindB);          // set pre gain, in dB scale
        void SetPreGainLinear(float fPreGainLinear);  // set pre gain, in linear scale
        int GetChannels() const;
    };

}  // namespace mammon
