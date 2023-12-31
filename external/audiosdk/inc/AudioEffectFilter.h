/* -*- c-basic-offset: 4 indent-tabs-mode: nil -*-  vi:set ts=8 sts=4 sw=4: */

/* Audio Effect Filter Library */

#pragma once

#include <cmath>
#include <string>
#include "ae_defs.h"

/**
 * @mainpage AudioEffectFilter
 *
 * The AudioEffectFilter API is contained in the single class
 * mammon::AudioEffectFilter.
 */

namespace mammon {

    class PitchTempoAdjuster;

    typedef enum effectName_e { UNDEF = 0, LADY, LASSOCK, TOMUNCLE, GHOST, ROBOT } effectName;

    typedef struct effectParam_s {
        // Shift formant or keep it when altering pitch.
        // Default: OptionFormantShifted
        bool formatShiftOn;
        // Enable time-domain smooting or not, after frequency pitch update
        // Default: OptionSmoothingOff
        bool smoothOn;
        // The way to adjust phase for consistent content from one analyzing widow to next.
        // Default: OptionPhaseLaminar
        // Joint or seperated processing for stereo input
        // Default: OptionChannelsApart
        int processChMode;
        // Transient detection method: Percussive/Compound/soft
        // Default: OptionDetectorCompound
        int transientDetectMode;
        // Phase reset on transient point in way of crsip/mixed/smooth;
        // Default: OptionTransientsCrisp
        int phaseResetMode;
        // The method to adjust phase: Cross-band(laminar) or Intra-band(Independent)
        // Default: OptionPhaseLaminar
        int phaseAdjustMethod;
        //	The FFT processing Window mode: short/standard/long
        // Default: OptionWindowStandard
        int windowMode;
        // The mode to conduct the pitch adjusting: speed/consistency/quality
        // Default: OptionPitchHighSpeed
        int pitchTunerMode;

        // Audio data block size for audio effect processing.
        // In general, could use 1024, 2048, 4096, ect.
        int blockSize;

        // Pitch tunning parameters
        // Rage: [-1200.0 - 1200.0]
        float centtone;
        // Rage: [-12, 12]
        float semitone;
        // Rage: [-3.0, 3.0]
        float octave;

        // Tempo tunning parameter, Future proof for case combined time- and frequency- effect.
        // Rage: [0.33, 3.0]
        float speedRatio;
    } effectParam;

    class MAMMON_DEPRECATED_EXPORT AudioEffectFilter {
    public:
        // Constructor only exposes effectId, which will simplify the calling.
        AudioEffectFilter(int sampleRate, size_t channels, int strEffectId = 0);
        // Constructor exposes verbose parameters(Contained in structure passed by caller) for each effectId, which will
        // provide flexibility for tuning.
        AudioEffectFilter(effectParam* effectParams, int sampleRate, size_t channels, int strEffectId = 0);
        // Constructor with verbose tunning parameters directly.
        AudioEffectFilter(bool formatShiftOn, bool smoothOn, int processChMode, int transientDetectMode,
                          int phaseResetMode, int phaseAdjustMethod, int windowMode, int pitchTunerMode, int blockSize,
                          float centtone, float semiton, float octative, float speedRatio, int sampleRate,
                          size_t channels, int strEffectId = 0);

        ~AudioEffectFilter();

        int MAMMON_DEPRECATED runImpl(float** inBuff, float** outBuff, const int samplesPerCh,
                                      const unsigned int offset);

        // Input buffer in format: inBuff[channel][sample]
        // Return the processed output size, considering the number of output audio samples may be different from ones
        // of input buffer
        int runImpl(float** inBuff, float** outBuff, const int samplesPerCh);
        int runImpl(float** inBuff, float** outBuff, int inSamplesPerCh, int outSamplesPerCh, int offsetIn,
                    int offsetOut);

        void updateRatio();
        void updateFormant();
        void updateFast();
        void initImpl();
        void updateCrispness();
        void updateCrispness(effectParam* effectParams);
        void updateCrispness(int transientDetectMode, int phaseResetMode, int phaseAdjustMethod, int windowMode);

        void setPitchScale(float ratio);

    protected:
        int m_strEffectId;

        // Some configuration parameters
        bool m_formantShiftOn;
        // crispness will decide based on transientDetectMode, phaseResetMode,
        // phaseAdjustMethod, windowMode.
        /** ||  m_crispness  ||  transientDetectMode || phaseResetMode || phaseAdjustMethod || windowMode||
             |     0          |  0(Compound)        |   2(No transient) |   1(Individual)    |  2(LongWin)|
             |     1          |  2(Soft)            |   0(Crisp)        |   1(Individual)    |  2(LongWin)|
             |     2          |  0(Compound)		|   2(No transient) |   1(Individual)    |  0(Standard)|
             |     3          |  0(Compound)        |   2(No transient) |   0(Laminar)	     |  0(Standard)|
             |     4		  |  0(Compound)        |   1(Mixed/Banded) |   0(Laminar)	     |  0(Standard)|
             |     5          |  0(Compound)        |   0(Crisp)		|   0(Laminar)       |  0(Standard)|
             |     6          |  0(Compound)        |   0(Crisp)        |   1(Individual)    |  1(Short)
        **/
        int m_crispness;
        bool m_fast;
        float m_centtone;
        float m_semitone;
        float m_octave;

        float m_ratio;
        float m_prevRatio;
        // float *m_latency;
        int m_currentCripness;
        bool m_currentFormant;
        bool m_currentFast;

        int m_sampleRate;
        size_t m_channels;
        size_t m_blockSize;
        size_t m_reserve;
        size_t m_minFill;

        PitchTempoAdjuster* m_pitchTuner;

        // data in de-interleaved format: data[ch][sample]
        // TODO: consider interveaved format processing.
        void** m_outBuffer;
        float** m_scratch;
    };

}  // namespace mammon
