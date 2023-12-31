//
// Created by william on 2019-04-16.
//

/* -*- c-basic-offset: 4 indent-tabs-mode: nil -*-  vi:set ts=8 sts=4 sw=4: */

/* Audio Effect Library */

#pragma once

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
struct ReverbDelayState {
    int pos;               // current write position
    int size;              // delay size
    float buf[REVERB_DS];  // delay buffer
};

// 1st order IIR filter
struct Reverb1stOrderState {
    float a2;  // coefficients
    float b1;
    float b2;
    float y1;  // state
};

// biquad
// step through the sound one sample at a time, one channel at a time
struct ReverbBiquadState {
    float b0;  // biquad coefficients
    float b1;
    float b2;
    float a1;
    float a2;
    float xn1;  // input[n - 1]
    float xn2;  // input[n - 2]
    float yn1;  // output[n - 1]
    float yn2;  // output[n - 2]
};

// early reflection
struct ReverbEarlyRefState {
    int delaytbl_left[EARLY_DELAY_SIZE], delaytbl_right[EARLY_DELAY_SIZE];
    ReverbDelayState delay_pwl, delay_pwr;
    ReverbDelayState delay_rl, delay_lr;
    ReverbBiquadState allpass_xl, allpass_xr;
    ReverbBiquadState allpass_left, allpass_right;
    Reverb1stOrderState lpf_left, lpf_right;
    Reverb1stOrderState hpf_left, hpf_right;
    float wet1, wet2;
};

// oversampling
struct ReverbOverSampleState {
    int factor;                          // oversampling factor [1 to REVERB_OF]
    ReverbBiquadState lpf_upsampling;    // lowpass filter used for upsampling
    ReverbBiquadState lpf_downsampling;  // lowpass filter used for downsampling
};

// dc cut
struct ReverbDcCutState {
    float gain;
    float y1;
    float y2;
};

// fractal noise cache
struct ReverbNoiseState {
    int pos;               // current read position in the buffer
    float buf[REVERB_NS];  // buffer filled with noise
};

// low-frequency oscilator (LFO)
struct ReverbLFOState {
    float re;   // real part
    float im;   // imaginary part
    float sn;   // sin of angle increment per sample
    float co;   // cos of angle increment per sample
    int count;  // number of samples generated so far (used to apply small corrections over time)
};

// all-pass filter with decay
struct ReverbAllPassState {
    int pos;
    int size;
    float feedback;
    float decay;
    float buf[REVERB_APS];
};

// 2nd order all-pass filter with decay
struct Reverb2ndOrderAllPassState {
    //    line 1                    line 2
    int pos1, pos2;
    int size1, size2;
    float feedback1, feedback2;
    float decay1, decay2;
    float buf1[REVERB_AP2S1], buf2[REVERB_AP2S2];
};

// 3rd order all-pass filter with modulation
struct Reverb3rdOrderAllPassState {
    //    line 1 (with modulation)              line 2              line 3
    int rpos1, wpos1, pos2, pos3;
    int size1, msize1, size2, size3;
    float feedback1, feedback2, feedback3;
    float decay1, decay2, decay3;
    float buf1[REVERB_AP3S1 + REVERB_AP3M1], buf2[REVERB_AP3S2], buf3[REVERB_AP3S3];
};

// modulated all-pass filter
struct ReverbModulatedAllPassState {
    int rpos, wpos;
    int size, msize;
    float feedback;
    float decay;
    float z1;
    float buf[SF_REVERB_APMS + SF_REVERB_APMM];
};

// comb filter

struct ReverbCombState {
    int pos;
    int size;
    float buf[SF_REVERB_CS];
};
struct ReverbParams {
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
};                         // add this struct for new member function - reset

//
// the final reverb state structure
//
// note: this struct is about 1Mb

struct RevertState {
    ReverbEarlyRefState earlyref;
    ReverbOverSampleState oversample_left, oversample_right;
    ReverbDcCutState dccut_left, dccut_right;
    ReverbNoiseState noise;
    ReverbLFOState lfo1;
    Reverb1stOrderState lfo1_lpf;
    ReverbModulatedAllPassState diff_left[10], diff_right[10];
    ReverbAllPassState cross_left[4], cross_right[4];
    Reverb1stOrderState clpf_left, clpf_right;                 // cross LPF
    ReverbDelayState cdelay_left, cdelay_right;                // cross delay
    ReverbBiquadState bassap_left, bassap_right;               // bass all-pass
    ReverbBiquadState basslp_left, basslp_right;               // bass lowpass
    Reverb1stOrderState damplp_left, damplp_right;             // dampening lowpass
    ReverbModulatedAllPassState dampap1_left, dampap1_right;   // dampening all-pass (1)
    ReverbDelayState dampd_left, dampd_right;                  // dampening delay
    ReverbModulatedAllPassState dampap2_left, dampap2_right;   // dampening all-pass (2)
    ReverbDelayState cbassd1_left, cbassd1_right;              // cross-fade bass delay (1)
    Reverb2ndOrderAllPassState cbassap1_left, cbassap1_right;  // cross-fade bass allpass (1)
    ReverbDelayState cbassd2_left, cbassd2_right;              // cross-fade bass delay (2)
    Reverb3rdOrderAllPassState cbassap2_left, cbassap2_right;  // cross-fade bass allpass (2)
    ReverbLFOState lfo2;
    Reverb1stOrderState lfo2_lpf;
    ReverbCombState comb_left, comb_right;
    ReverbBiquadState lastlpf_left, lastlpf_right;
    ReverbDelayState lastdelay_left, lastdelay_right;
    ReverbDelayState inpdelay_left, inpdelay_right;
    int outco[32];
    float loopdecay;
    float wet1, wet2;
    float wander;
    float bassb;
    float ertolate;  // early reflection mix parameters
    float erefwet;
    float dry;

    ReverbParams params;
};

// configure a reverb state with advanced parameters
void configReverbX(RevertState* rv,
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
void reverbResetX(RevertState* rv);

void reverbProcessX(RevertState* rv, float input_left, float input_right, float* output_left, float* output_right);

#ifdef __cplusplus
}
#endif