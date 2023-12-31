/* -*- c-basic-offset: 4 indent-tabs-mode: nil -*-  vi:set ts=8 sts=4 sw=4: */

/* Audio Effect Library */
#pragma once

#include <stddef.h>
#include "ae_defs.h"
#define EQ_BANDS_MAX 10

namespace mammon {

    class MAMMON_DEPRECATED_EXPORT Equalizer {
    public:
        /* User customized settings. */
        typedef struct _eq_customized_t {
            float f_preamp;                  /* Full band pre-amplitude gain. */
            float f_freqWidth[EQ_BANDS_MAX]; /* The percent of octave width of frequency for each frequency band. */
            float f_amp[EQ_BANDS_MAX];       /* 10 band gains */
        } eq_customized_t;

        /* Initialization with preset id, the setting could be overritted by customized settings, if any. */
        Equalizer(int sampleRate, int channels, int presetId = 0, eq_customized_t* eq_customized = NULL,
                  bool b2ndPass = false);
        ~Equalizer();

        void applyClipping(bool apply);
        /* Note: in and out audio data should be interleaved! */
        // This process function is the original design which configures EQ with presetId
        void process(float* in, float* out, int samplesIn, int presetId);
        // This process remove presetId, which means caller responsible for update CustomizedSettings and ignore the
        // presetId.
        void process(float* in, float* out, int samplesIn);
        /* Update the preset or the customized settings for EQ. */
        int updateCustomizedSetting(eq_customized_t* eq_customized);
        int updatePreset(int presetId);
        /* reset state */
        void reset();
        /* Export the band config and preset config of eq.*/
        unsigned eqGetBandCount();
        float eqGetBandFre(unsigned uIndex);
        unsigned eqGetPresetNum();
        const char* eqGetPresetName(unsigned uIndex);

    private:
        typedef struct _equalizer_config_t {
            float* m_alpha;
            float* m_beta;
            float* m_gamma;
        } m_eq_config_t;

        void eqCoeffInit(int sampleRate, float* octave_percent, m_eq_config_t* cfg);
        float eqdB2Gain(float dB);

        int m_presetId; /* count starting from 0 */
        bool m_customEn;
        int m_channels;
        int m_sampleRate;
        float* m_octPercentPerband;
        /* Equalizer static config */
        int m_band;
        m_eq_config_t* m_cfg;
        /* Equalizer dynamic config */
        bool m_2passEq;
        float* m_gainPerband; /* amplitude gain */
        float m_gainGlobal;   /* global amplitude gain */

        /* Equalizer state */
        float** m_x;   /* [ch][2] */
        float** m_x2;  /* [ch][2] */
        float*** m_y;  /* [ch][band][2] */
        float*** m_y2; /* Second filter state */

        bool m_applyClipping;
    };

    class ParametricEqulizer {
    public:
        /* Parametric Equalizer static config */
        typedef struct _param_eq_config_t {
            float m_lowFre, m_lowSlope, m_lowGain;
            float m_f1, m_q1, m_gain1;
            float m_f2, m_q2, m_gain2;
            float m_f3, m_q3, m_gain3;
            float m_highFre, m_highSlope, m_highGain;
        } m_param_eq_config_t;

        ParametricEqulizer(int sampleRate, int channels, m_param_eq_config_t* paraEqConfg);
        ~ParametricEqulizer();
        /* Note: in and out audio data should be interleaved! */
        void process(float* in, float* out, int samples);

    private:
        void paramShelfEqCoeffInit(float sampleRate, float f, float slope, float gain, float* coeff, bool low);
        void paramPeakEqCoeffInit(float sampleRate, float f, float Q, float gain, float* coeff);

        int m_sampleRate;
        int m_channels;
        /* The number of parameric eq. */
        int parametricEqNum;

        /* Parametric Equalizer state */
        /* Biquad need 4 states for each IIR filter for each channel*/
        float* m_state;
        /* Parametric coeffs */
        /* Biquad need 5 coeffs for each IIR filter */
        float* m_coeffs;
    };

    /// RIAA phono equalizer, which could shrink the audio signal bandwith with RIAA EQ
    /// to give kind of "warm/granular sensation" hearing experiences.
    class RiaaEq {
    public:
        RiaaEq(int sampleRate, int channels, bool inverseRIAA = 0);
        ~RiaaEq(){};

        void setCoefficients(float sampleRate, bool inverseRIAA);
        void process(float** in, float** out, int samplePerCh);
        void clear();

    private:
        int m_sampleRate;
        int m_ch;
        float m_a0, m_a1, m_a2;
        float m_b0, m_b1, m_b2;
        // Buffered I/O data
        // Now only stereo audio supported
        float m_inL1, m_inL2, m_inR1, m_inR2;
        float m_outL1, m_outL2, m_outR1, m_outR2;
    };
}  // namespace mammon
