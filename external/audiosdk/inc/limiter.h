/* -*- c-basic-offset: 4 indent-tabs-mode: nil -*-  vi:set ts=8 sts=4 sw=4: */

/* Audio Effect Library */

#pragma once

#include "ae_defs.h"

namespace mammon {

    /** A multi-channel limiter
     * Method: low pass filter the absolute value of each channel and find the maximum over
     * all these channels and then use the reciprocal of maximum for the gain.
     */
    class MAMMON_DEPRECATED Limiter {
    public:
        /// @param nSampleRateHz sample rate in Hz.
        /// @param nChannels the number of channels
        /// @param fGain the signal (when small) just gets multiplied by this value
        /// @param fRMSMax the signal is limited to below this value.
        /// @param fAttackTime the attack time in seconds
        /// @param fReleaseTime the release time in seconds.
        Limiter(int nSampleRateHz, int nChannels, float fGain, float fRMSMax, float fAttackTime, float fReleaseTime);
        ~Limiter() = default;
        /* @param pIn Input audio data in interleaved format.
         * @param pOut Output audio data in interleaved format.
         * @param lenPerCh  Audio data for each channel. */
        void process(float* pIn, float* pOut, int lenPerCh);
        /* @param apfIn Input audio data in non-interleaved format.
         * @param apFout Output audio data also in non-interleaved format.
         * @param lenPerCh Audio data for each channel. */
        void processPlane(float** apfIn, float** apfOut, int lenPerCh);

        void updateGain(float fGain);

    private:
        float m_flpf;
        float m_fc0;
        float m_fc1;
        float m_fRMSMax;
        float m_nChannels;
        float m_fk;
    };
}  // namespace mammon
