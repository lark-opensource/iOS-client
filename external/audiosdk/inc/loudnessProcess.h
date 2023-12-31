/* -*- c-basic-offset: 4 indent-tabs-mode: nil -*-  vi:set ts=8 sts=4 sw=4: */

/* Audio Effect Library */

#pragma once

#include "ae_defs.h"

namespace mammon {
    class PeakAnalysis;
    class Limiter;

    typedef enum _clipMode {
        // Enhance the perceived volume with sin modulation algorithm,
        // this algorithm won't clip by itself.
        ENHANCE_NO_CLIP = -1,
        /// reduce the gain change to avoid clipping where necessary
        /// THIS REQUIRES the peak detector to have been run.
        REDUCE_SCALE_NO_CLIP,
        /// do the gain change and use soft clipping where necessary
        SOFT_CLIP,
        /// do the gain change and use a limiter and soft clipping
        /// where necessary
        SOFT_CLIP_WITH_LIMITER,
        /// do the gain scale and hard clip.
        HARD_CLIP
    } clipMode_t;

    class MAMMON_DEPRECATED_EXPORT LoudnessProcess {
    public:
        /**
         * @param fAdjustGainDB The gain adjusted.
         * @param contrast This parameter will non-linear compress the audio to make it sound louder. The range will be
         *in [0, 0.1]. Note that 0 will also make the audio sound louder. Larger value will make it much lounder.
         * @param fRMSMaxDB The RMS level(in dBFS) that limiter use to ensure it's never get exceeded. Default is set to
         *-5.0 dBFS
         * @param fPeak If provided(PeakAnalysis has been run before calling this), then m_bClip could be judged base on
         *this value.
         * @param fAttackTime The attack time for the limiter in seconds. Default is set to 40.1642ms.
         * @param fReleaseTime The releae time for the limiter in seconds. Default is set to 743.039ms.
         */
        LoudnessProcess(int sampleRate, int nCh, clipMode_t eClipMode, float fAdjustGainDB = 0, float contrast = 0,
                        float fPeak = 1.0f, float fRMSMaxDB = -5.0f, float fAttackTime = 0.0401642f,
                        float fReleaseTime = 0.743039f);
        ~LoudnessProcess();
        /* @param pfIn Input audio buffer in interleaved format.
         * @param pfOut Output audio buffer in interleaved format.
         * @param lenPerCh Audio length each channel for each processing call.
         */
        void process(float* pfIn, float* pfOut, int lenPerCh);
        /* @param ppfIn Input audio buffer in non-interleaved format.
         * @param ppfOut Output audio buffer in non-interleaved format.
         * @param lenPerCh Audio length each channel for each processing call.
         */
        void processPlane(float** ppfIn, float** ppfOut, int lenPerCh);
        void updateGain(float fAdjustGainDB);

    private:
        int m_nChannels;
        int m_nSamplerate;
        clipMode_t m_eClipMode;
        bool m_bClip;
        float m_fGain;
        float m_contrast;
        float m_fRequestedPeak;
        float m_fRMSMax;
        float m_fAttackTIme;
        float m_fReleaseTime;
        Limiter* m_pLimiter = nullptr;
        PeakAnalysis* m_pPeakAnalysis = nullptr;

        void determineClipping();
    };

}  // namespace mammon
