/* -*- c-basic-offset: 4 indent-tabs-mode: nil -*-  vi:set ts=8 sts=4 sw=4: */

/* Audio Effect Library */

#pragma once

#include "ae_defs.h"

#ifdef __cplusplus
extern "C" {
#endif

#include "ae_reverb2_mode.h"

// non-convolution parametric based reverb effects
// The drawback of this algorithm is comsuming too much memory, which may limit the utilization on mobile
// this particular setup uses the following components:
//    1. Delay
//    2. 1st order IIR filter (lowpass filter, highpass filter)
//    3. Biquad filter (lowpass filter, all-pass filter)
//    4. Early reflection
//    5. Oversampling
//    6. DC cut
//    7. Fractal noise
//    8. Low-frequency oscilator (LFO)
//    9. All-pass filter
//   10. 2nd order All-pass filter
//   11. 3rd order All-pass filter with modulation
//   12. Modulated all-pass filter
//   13. Delayed feedforward comb filter
//
// each of these components is broken into their own structures (rv_*), and the reverb effect
// uses these in the final state structure (reverb_state_st)
//
// each component is designed to work one step at a time, so any size sample can be streamed through
// in one pass

// delay buffer size in samples; maximum size allowed for a delay
#define REVERB_DS 3000
// maximum oversampling factor
#define REVERB_OF 2
// noise buffer size; must be a power of 2 because it's generated via fractal generator
#define REVERB_NS (1 << 11)
// maximum size for 1st order all-pass filter
#define REVERB_APS 3400
// maximum sizes of the two buffers in 2nd order all-pass filter
#define REVERB_AP2S1 4200
#define REVERB_AP2S2 3000
// maximum sizes of the three buffers and maximum mod size of the first line for 3rd order all-pass filter with
// modulation.
#define REVERB_AP3S1 4000
#define REVERB_AP3M1 600
#define REVERB_AP3S2 2000
#define REVERB_AP3S3 3000
// maximum size and maximum mod size for modulated all-pass filter
#define SF_REVERB_APMS 3600
#define SF_REVERB_APMM 137
// Early reflection delay buffer size
#define EARLY_DELAY_SIZE 18
// maximum size of the buffer for comb filter
#define SF_REVERB_CS 1500

// delay
typedef struct {
    int pos;               // current write position
    int size;              // delay size
    float buf[REVERB_DS];  // delay buffer
} rv_delay_st;

// 1st order IIR filter
typedef struct {
    float a2;  // coefficients
    float b1;
    float b2;
    float y1;  // state
} rv_iir1_st;

// biquad
// step through the sound one sample at a time, one channel at a time
typedef struct {
    float b0;  // biquad coefficients
    float b1;
    float b2;
    float a1;
    float a2;
    float xn1;  // input[n - 1]
    float xn2;  // input[n - 2]
    float yn1;  // output[n - 1]
    float yn2;  // output[n - 2]
} rv_biquad_st;

// early reflection
typedef struct {
    int delaytblL[EARLY_DELAY_SIZE], delaytblR[EARLY_DELAY_SIZE];
    rv_delay_st delayPWL, delayPWR;
    rv_delay_st delayRL, delayLR;
    rv_biquad_st allpassXL, allpassXR;
    rv_biquad_st allpassL, allpassR;
    rv_iir1_st lpfL, lpfR;
    rv_iir1_st hpfL, hpfR;
    float wet1, wet2;
} rv_earlyref_st;

// oversampling
typedef struct {
    int factor;         // oversampling factor [1 to REVERB_OF]
    rv_biquad_st lpfU;  // lowpass filter used for upsampling
    rv_biquad_st lpfD;  // lowpass filter used for downsampling
} rv_oversample_st;

// dc cut
typedef struct {
    float gain;
    float y1;
    float y2;
} rv_dccut_st;

// fractal noise cache
typedef struct {
    int pos;               // current read position in the buffer
    float buf[REVERB_NS];  // buffer filled with noise
} rv_noise_st;

// low-frequency oscilator (LFO)
typedef struct {
    float re;   // real part
    float im;   // imaginary part
    float sn;   // sin of angle increment per sample
    float co;   // cos of angle increment per sample
    int count;  // number of samples generated so far (used to apply small corrections over time)
} rv_lfo_st;

// all-pass filter with decay
typedef struct {
    int pos;
    int size;
    float feedback;
    float decay;
    float buf[REVERB_APS];
} rv_allpass_st;

// 2nd order all-pass filter with decay
typedef struct {
    //    line 1                    line 2
    int pos1, pos2;
    int size1, size2;
    float feedback1, feedback2;
    float decay1, decay2;
    float buf1[REVERB_AP2S1], buf2[REVERB_AP2S2];
} rv_allpass2_st;

// 3rd order all-pass filter with modulation
typedef struct {
    //    line 1 (with modulation)              line 2              line 3
    int rpos1, wpos1, pos2, pos3;
    int size1, msize1, size2, size3;
    float feedback1, feedback2, feedback3;
    float decay1, decay2, decay3;
    float buf1[REVERB_AP3S1 + REVERB_AP3M1], buf2[REVERB_AP3S2], buf3[REVERB_AP3S3];
} rv_allpass3_st;

// modulated all-pass filter
typedef struct {
    int rpos, wpos;
    int size, msize;
    float feedback;
    float decay;
    float z1;
    float buf[SF_REVERB_APMS + SF_REVERB_APMM];
} rv_allpassm_st;

// comb filter
typedef struct {
    int pos;
    int size;
    float buf[SF_REVERB_CS];
} rv_comb_st;

typedef struct {
    int rate;              // input sample rate (samples per second)
    int oversamplefactor;  // how much to oversample [1 to 2]
    float ertolate;        // early reflection amount [0 to 1]
    float erefwet;         // dB, final wet mix [-70 to 10]
    float dry;             // dB, final dry mix [-70 to 10]
    float ereffactor;      // early reflection factor [0.5 to 2.5]
    float erefwidth;       // early reflection width [-1 to 1]
    float width;           // width of reverb L/R mix [0 to 1]
    float wet;             // dB, reverb wetness [-70 to 10]
    float wander;          // LFO wander amount [0.1 to 0.6]
    float bassb;           // bass boost [0 to 0.5]
    float spin;            // LFO spin amount [0 to 10]
    float inputlpf;        // Hz, lowpass cutoff for input [200 to 18000]
    float basslpf;         // Hz, lowpass cutoff for bass [50 to 1050]
    float damplpf;         // Hz, lowpass cutoff for dampening [200 to 18000]
    float outputlpf;       // Hz, lowpass cutoff for output [200 to 18000]
    float rt60;            // reverb time decay [0.1 to 30]
    float delay;           // seconds, amount of delay [-0.5 to 0.5]
} reverb_params;           // add this struct for new member function - reset

//
// the final reverb state structure
//
// note: this struct is about 1Mb
typedef struct {
    rv_earlyref_st earlyref;
    rv_oversample_st oversampleL, oversampleR;
    rv_dccut_st dccutL, dccutR;
    rv_noise_st noise;
    rv_lfo_st lfo1;
    rv_iir1_st lfo1_lpf;
    rv_allpassm_st diffL[10], diffR[10];
    rv_allpass_st crossL[4], crossR[4];
    rv_iir1_st clpfL, clpfR;              // cross LPF
    rv_delay_st cdelayL, cdelayR;         // cross delay
    rv_biquad_st bassapL, bassapR;        // bass all-pass
    rv_biquad_st basslpL, basslpR;        // bass lowpass
    rv_iir1_st damplpL, damplpR;          // dampening lowpass
    rv_allpassm_st dampap1L, dampap1R;    // dampening all-pass (1)
    rv_delay_st dampdL, dampdR;           // dampening delay
    rv_allpassm_st dampap2L, dampap2R;    // dampening all-pass (2)
    rv_delay_st cbassd1L, cbassd1R;       // cross-fade bass delay (1)
    rv_allpass2_st cbassap1L, cbassap1R;  // cross-fade bass allpass (1)
    rv_delay_st cbassd2L, cbassd2R;       // cross-fade bass delay (2)
    rv_allpass3_st cbassap2L, cbassap2R;  // cross-fade bass allpass (2)
    rv_lfo_st lfo2;
    rv_iir1_st lfo2_lpf;
    rv_comb_st combL, combR;
    rv_biquad_st lastlpfL, lastlpfR;
    rv_delay_st lastdelayL, lastdelayR;
    rv_delay_st inpdelayL, inpdelayR;
    int outco[32];
    float loopdecay;
    float wet1, wet2;
    float wander;
    float bassb;
    float ertolate;  // early reflection mix parameters
    float erefwet;
    float dry;

    reverb_params _params;
} reverb_state_st;

typedef enum ReverbMode reverb_preset;

// configure a reverb state with a preset
MAMMON_DEPRECATED void presetReverb(reverb_state_st* state, int rate, reverb_preset preset);

// configure a reverb state with advanced parameters
MAMMON_DEPRECATED_EXPORT void configReverb(reverb_state_st* rv,
                                           int rate,              // input sample rate (samples per second)
                                           int oversamplefactor,  // how much to oversample [1 to 2]
                                           float ertolate,        // early reflection amount [0 to 1]
                                           float erefwet,         // dB, final wet mix [-70 to 10]
                                           float dry,             // dB, final dry mix [-70 to 10]
                                           float ereffactor,      // early reflection factor [0.5 to 2.5]
                                           float erefwidth,       // early reflection width [-1 to 1]
                                           float width,           // width of reverb L/R mix [0 to 1]
                                           float wet,             // dB, reverb wetness [-70 to 10]
                                           float wander,          // LFO wander amount [0.1 to 0.6]
                                           float bassb,           // bass boost [0 to 0.5]
                                           float spin,            // LFO spin amount [0 to 10]
                                           float inputlpf,        // Hz, lowpass cutoff for input [200 to 18000]
                                           float basslpf,         // Hz, lowpass cutoff for bass [50 to 1050]
                                           float damplpf,         // Hz, lowpass cutoff for dampening [200 to 18000]
                                           float outputlpf,       // Hz, lowpass cutoff for output [200 to 18000]
                                           float rt60,            // reverb time decay [0.1 to 30]
                                           float delay            // seconds, amount of delay [-0.5 to 0.5]
);

// reset状态
MAMMON_DEPRECATED void reverbReset(reverb_state_st* rv);

// this function will process the input sound based on the state passed
// the input and output buffers should be the same size
MAMMON_DEPRECATED_EXPORT void reverbProcess(reverb_state_st* rv, float inputL, float inputR, float* outputL,
                                            float* outputR);
#ifdef __cplusplus
}
#endif
