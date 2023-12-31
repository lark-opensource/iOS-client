/* -*- c-basic-offset: 4 indent-tabs-mode: nil -*-  vi:set ts=8 sts=4 sw=4: */

/* Audio Effect Library */

#pragma once

#include "ae_defs.h"
#include "filter.h"

#define COMBFILTERNUM    (8)
#define ALLPASSFILTERNUM (4)
// Pre-allocate the buffer for 48Khz sampling
#define STEREOOFFSET (25)
#define ALLPASSLENL1 (605)
#define ALLPASSLENR1 (605 + STEREOOFFSET)
#define ALLPASSLENL2 (480)
#define ALLPASSLENR2 (480 + STEREOOFFSET)
#define ALLPASSLENL3 (371)
#define ALLPASSLENR3 (371 + STEREOOFFSET)
#define ALLPASSLENL4 (244)
#define ALLPASSLENR4 (244 + STEREOOFFSET)
#define COMBLENL1    (1214)
#define COMBLENR1    (1214 + STEREOOFFSET)
#define COMBLENL2    (1293)
#define COMBLENR2    (1293 + STEREOOFFSET)
#define COMBLENL3    (1389)
#define COMBLENR3    (1389 + STEREOOFFSET)
#define COMBLENL4    (1475)
#define COMBLENR4    (1475 + STEREOOFFSET)
#define COMBLENL5    (1547)
#define COMBLENR5    (1547 + STEREOOFFSET)
#define COMBLENL6    (1622)
#define COMBLENR6    (1622 + STEREOOFFSET)
#define COMBLENL7    (1694)
#define COMBLENR7    (1694 + STEREOOFFSET)
#define COMBLENL8    (1760)
#define COMBLENR8    (1760 + STEREOOFFSET)
// Resample the buffer for 441KHz input
#define STEREOOFFSET_441K (23)
#define ALLPASSLENL1_441K (556)
#define ALLPASSLENR1_441K (556 + STEREOOFFSET)
#define ALLPASSLENL2_441K (441)
#define ALLPASSLENR2_441K (441 + STEREOOFFSET)
#define ALLPASSLENL3_441K (341)
#define ALLPASSLENR3_441K (341 + STEREOOFFSET)
#define ALLPASSLENL4_441K (225)
#define ALLPASSLENR4_441K (225 + STEREOOFFSET)
#define COMBLENL1_441K    (1116)
#define COMBLENR1_441K    (1116 + STEREOOFFSET)
#define COMBLENL2_441K    (1188)
#define COMBLENR2_441K    (1188 + STEREOOFFSET)
#define COMBLENL3_441K    (1277)
#define COMBLENR3_441K    (1277 + STEREOOFFSET)
#define COMBLENL4_441K    (1356)
#define COMBLENR4_441K    (1356 + STEREOOFFSET)
#define COMBLENL5_441K    (1422)
#define COMBLENR5_441K    (1422 + STEREOOFFSET)
#define COMBLENL6_441K    (1491)
#define COMBLENR6_441K    (1491 + STEREOOFFSET)
#define COMBLENL7_441K    (1557)
#define COMBLENR7_441K    (1557 + STEREOOFFSET)
#define COMBLENL8_441K    (1617)
#define COMBLENR8_441K    (1617 + STEREOOFFSET)

namespace mammon {
    class MAMMON_DEPRECATED_EXPORT Reverb {
    public:
        /** Reverb filters
         * @param sampleRate The predefined comb and all-pass filters lens are based on 44.1KHz, which does not work for
         high samplerate such as 96Khz. So, need to resample it.
         * @param ch The number of channels of input audio samples.
         * @param roomSize The room size emulated by filter. Value should be in range [0.0, 1.5].
                Note: too large value will add too much comb feedback and make the audio echo too much and add wind
         noise.
         * @param hfDamping The Damping will simulate the phenomenon that high frequency part will be absorbed more than
         lower frequency part. Value should be in range [0.0, 0.9]. Too large value will add high frequency noise(hiss)
         or even make the filter diverse.
         * @param stereoDepth To indicate the width of L/R stereo audio image. Value should be in range [0.0, 1.0].
            0.5 will give the best balanced mix, while 0.0 will pan more to R, 1.0 will pan more to L.
         * @param dry Set the dry part in linear gain. negative value will revert the phase of dry part.
            larger absolute value |X| will boost the dry part in |X| times for audio amplitude.
         * @param wet Set the wet part in linear gain. negative value will revert the phase of wet part.
            larger absolute value |X| will boost the wet part in |X| times for audio amplitude.
         * @param dryGainDB Set the dry part in dB gain. Negative value will reduce the volume(in dB) in dry part and
         positive will boost it.
         * @param wetGainDB Set the wet part in dB gain. Negative value will reduce the volume(in dB) in wet part and
         positive will boost it.
         * @param dryOnly Will only gives the un-filtered dry audio.
         * @param wetOnly will only gives the filtered wet audio.
         */
        Reverb(int sampleRate, int ch, float roomSize, float hfDamping, float stereoDepth, float dry, float wet,
               float dryGainDB = 0, float wetGainDB = 0, bool dryOnly = 0, bool wetOnly = 0);
        ~Reverb();
        // input and output buffer in interleaved format: buf[ch * sample].
        void process(float* inBuf, float* outBuf, int samplePerCh);
        void processPlanar(float* in_left, float* in_right, float* out_left, float* out_right, int samples_per_ch);
        void setRoomSize(float roomSize);
        float getRoomSize();
        void setDamp(float hfDamping);
        float getDamp();
        void setStereoDepth(float stereoDepth);
        float getStereoDepth();
        void setDry(float dry);
        float getDry();
        void setWet(float wet);
        float getWet();
        void setDryGain(float dryGainDB);
        float getDryGain();
        void setWetGain(float wetGainDB);
        float getWetGain();

        void reset();

    private:
        struct reverb_params {
            int sampleRate;
            int ch;
            float roomSize;
            float hfDamping;
            float stereoDepth;
            float dry;
            float wet;
            float dryGainDB;
            float wetGainDB;
            bool dryOnly;
            bool wetOnly;

            reverb_params() = default;
            reverb_params(int sampleRate, int ch, float roomSize, float hfDamping, float stereoDepth, float dry,
                          float wet, float dryGainDB, float wetGainDB, bool dryOnly, bool wetOnly)

                : sampleRate(sampleRate), ch(ch), roomSize(roomSize), hfDamping(hfDamping), stereoDepth(stereoDepth),
                  dry(dry), wet(wet), dryGainDB(dryGainDB), wetGainDB(wetGainDB), dryOnly(dryOnly), wetOnly(wetOnly) {
            }
        };

        reverb_params _params;

        void init(int sampleRate, int ch, float roomSize, float hfDamping, float stereoDepth, float dry, float wet,
                  float dryGainDB, float wetGainDB, bool dryOnly, bool wetOnly);

    private:
        void filterProcess(float* bufIn, float* bufOut, int ch);
        void filterProcessPlanar(float* in_left, float* in_right, float* out_left, float* out_right);
        void resetBuf();
        void reconfig();
        float db2Linear(float gaindB);
        float linear2Db(float gain);

        int m_sampleRate;
        int m_ch;

        float m_roomSize;
        float m_hfDamping;
        float m_stereoDepth;
        // the internal dry and wet signal
        float m_dry;
        float m_wet, m_wet1, m_wet2;
        // Linear gain = 1/20 * log10(gaindB)
        float m_dryGain, m_wetGain;

        // mainly for test
        bool m_dryOnly;
        bool m_wetOnly;

        CombFilter m_combL[COMBFILTERNUM];
        CombFilter m_combR[COMBFILTERNUM];
        AllPassFilter m_allPassL[ALLPASSFILTERNUM];
        AllPassFilter m_allPassR[ALLPASSFILTERNUM];

        // stacking buffers to avoid memory allocation budget
        // the drawback is excess pre-allocated size for 44.1Khz than required.
        float m_bufCombL1[COMBLENL1];
        float m_bufCombR1[COMBLENR1];
        float m_bufCombL2[COMBLENL2];
        float m_bufCombR2[COMBLENR2];
        float m_bufCombL3[COMBLENL3];
        float m_bufCombR3[COMBLENR3];
        float m_bufCombL4[COMBLENL4];
        float m_bufCombR4[COMBLENR4];
        float m_bufCombL5[COMBLENL5];
        float m_bufCombR5[COMBLENR5];
        float m_bufCombL6[COMBLENL6];
        float m_bufCombR6[COMBLENR6];
        float m_bufCombL7[COMBLENL7];
        float m_bufCombR7[COMBLENR7];
        float m_bufCombL8[COMBLENL8];
        float m_bufCombR8[COMBLENR8];

        float m_bufAllPassL1[ALLPASSLENL1];
        float m_bufAllPassR1[ALLPASSLENR1];
        float m_bufAllPassL2[ALLPASSLENL2];
        float m_bufAllPassR2[ALLPASSLENR2];
        float m_bufAllPassL3[ALLPASSLENL3];
        float m_bufAllPassR3[ALLPASSLENR3];
        float m_bufAllPassL4[ALLPASSLENL4];
        float m_bufAllPassR4[ALLPASSLENR4];
    };

}  // namespace mammon