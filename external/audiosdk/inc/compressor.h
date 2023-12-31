// Dynamic Range Compressor, created by Hequn BAI @bytedance

// (c) Copyright 2016, Sean Connelly (@voidqk), http://syntheti.cc
// MIT License
// Project Home: https://github.com/voidqk/sndfilter

// dynamics compressor based on WebAudio specification:
// https://webaudio.github.io/web-audio-api/#the-dynamicscompressornode-interface

/*
  The MIT License (MIT)

Copyright (c) 2016 Sean Connelly (@voidqk, web: syntheti.cc)

Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all
copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
SOFTWARE.
 */

#pragma once
#include "ae_defs.h"

namespace mammon {

// dynamic range compression is a complex topic with many different algorithms
//
// this API works by first initializing an sf_compressor_state_st structure, then using it to
// process a sample in chunks
//
// notice that sf_compressor_process will change a lot of the member variables inside of the state
// structure, since these values must be carried over across chunk boundaries
//
// also notice that the choice to divide the sound into chunks of 128 samples is completely
// arbitrary from the compressor's perspective, however, the size should be divisible by the SPU
// value below (defaults to 32):

// maximum number of samples in the delay buffer
#define SF_COMPRESSOR_MAXDELAY 1024

// samples per update; the compressor works by dividing the input chunks into even smaller sizes,
// and performs heavier calculations after each mini-chunk to adjust the final envelope
#define SF_COMPRESSOR_SPU 256  // 28 //32

// not sure what this does exactly, but it is part of the release curve
#define SF_COMPRESSOR_SPACINGDB 5.0f

    typedef struct {
        int rate;
        float pregain;
        float threshold;
        float knee;
        float ratio;
        float attack;
        float release;
        float predelay;      // seconds; length of the predelay buffer [0 to 1]
        float releasezone1;  // release zones should be increasing between 0 and 1; and are a fraction
        float releasezone2;  //  of the release time depending on the input dB -- these parameters define
        float releasezone3;  //  the adaptive release curve; which is discussed in further detail in the
        float releasezone4;  //  demo: adaptive-release-curve.html
        float postgain;      // dB; amount of gain to apply after compression [0 to 100]
        float wet;
    } compressor_params;

    typedef struct {
        // user can read the metergain state variable after processing a chunk to see how much dB the
        // compressor would have liked to compress the sample; the meter values aren't used to shape the
        // sound in any way, only used for output if desired
        float metergain;

        // everything else shouldn't really be mucked with unless you read the algorithm and feel
        // comfortable
        float meterrelease;
        float threshold;
        float knee;
        float linearpregain;
        float linearthreshold;
        float slope;
        float attacksamplesinv;
        float satreleasesamplesinv;
        float wet;
        float dry;
        float k;
        float kneedboffset;
        float linearthresholdknee;
        float mastergain;
        float a;  // adaptive release polynomial coefficients
        float b;
        float c;
        float d;
        float detectoravg;
        float detectoravg_thd;    // BAI
        float attenuationdb_thd;  // BAI
        float compgain;
        float maxcompdiffdb;
        int delaybufsize;
        int delaywritepos;
        int delayreadpos;
        float delaybuf[SF_COMPRESSOR_MAXDELAY];    // BAI: for mono audio and stereo audio left channel
        float delaybufLR[SF_COMPRESSOR_MAXDELAY];  // BAI: for stereo audio right channel
        // sf_sample_st delaybuf[SF_COMPRESSOR_MAXDELAY]; // predelay buffer

        // for reset() only
        compressor_params _params;
        float momentary_max;
        int print_count;
    } sf_compressor_state_st;

    // populate a compressor state with all default values
    MAMMON_DEPRECATED_EXPORT void sf_defaultcomp(sf_compressor_state_st* state, int rate);

    // populate a compressor state with simple parameters
    MAMMON_DEPRECATED_EXPORT void sf_simplecomp(
        sf_compressor_state_st* state,
        int rate,         // input sample rate (samples per second)
        float pregain,    // dB, amount to boost the signal before applying compression [0 to 100]
        float threshold,  // dB, level where compression kicks in [-20 to 0] //[-100 to 0]
        float knee,       // dB, width of the knee [0 to 40]
        float ratio,      // unitless, amount to inversely scale the output when applying comp [1 to 20]
        float attack,     // seconds, length of the attack phase [0 to 1]
        float release     // seconds, length of the release phase [0 to 1]
    );

    // populate a compressor state with advanced parameters
    MAMMON_DEPRECATED_EXPORT void sf_advancecomp(
        sf_compressor_state_st* state,
        // these parameters are the same as the simple version above:
        int rate, float pregain, float threshold, float knee, float ratio, float attack, float release,
        // these are the advanced parameters:
        float predelay,      // seconds, length of the predelay buffer [0 to 1]
        float releasezone1,  // release zones should be increasing between 0 and 1, and are a fraction
        float releasezone2,  //  of the release time depending on the input dB -- these parameters define
        float releasezone3,  //  the adaptive release curve, which is discussed in further detail in the
        float releasezone4,  //  demo: adaptive-release-curve.html
        float postgain,      // dB, amount of gain to apply after compression [0 to 100]
        float wet            // amount to apply the effect [0 completely dry to 1 completely wet]
    );

    // populate a compressor state with multi-slope parameters
    MAMMON_DEPRECATED_EXPORT void sf_multislopecomp(
        sf_compressor_state_st* state,
        // these parameters are the same as the simple version above:
        int rate, float pregain, float threshold, float knee, float ratio, float attack, float release,
        // these are the advanced parameters:
        float predelay,           // seconds, length of the predelay buffer [0 to 1]
        float releasezone1,       // release zones should be increasing between 0 and 1, and are a fraction
        float releasezone2,       //  of the release time depending on the input dB -- these parameters define
        float releasezone3,       //  the adaptive release curve, which is discussed in further detail in the
        float releasezone4,       //  demo: adaptive-release-curve.html
        float postgain,           // dB, amount of gain to apply after compression [0 to 100]
        float wet,                // amount to apply the effect [0 completely dry to 1 completely wet]
                                  // these are the multi-slope parameters:
        float attenuationdb_thd,  // (0~2.0)dB, determines the slope of the first part, BAI
        float detectoravg_thd     // (0~1.0), determines the slope of the second part, BAI
                                  // ratio determines the slope of the third part,
                                  // detectoravg_thd, ratio and knee together determine the knee curve
    );

    // reset state
    MAMMON_DEPRECATED_EXPORT void sf_compressor_reset(sf_compressor_state_st* state);

    // this function will process the input sound based on the state passed
    // the input and output buffers should be the same size
    MAMMON_DEPRECATED_EXPORT void sf_compressor_process_mono(sf_compressor_state_st* state, int size, float* input,
                                                             float* output);  // BAI

    // stereo input, stereo output, interleaved order (LRLRLR...) size = frame_length * 2
    MAMMON_DEPRECATED_EXPORT void sf_compressor_process_stereo_interleaved(sf_compressor_state_st* state, int size,
                                                                           float* input,
                                                                           float* output);  // BAI

    MAMMON_DEPRECATED_EXPORT void sf_compressor_process_stereo(sf_compressor_state_st* state, int size, float* inputL,
                                                               float* inputR, float* outputL, float* outputR);  // BAI

    MAMMON_DEPRECATED_EXPORT void sf_compressor_process_stereo_sidechain(sf_compressor_state_st* state, int size,
                                                                         float* inputBufferL_sidechain,
                                                                         float* inputBufferR_sidechain,
                                                                         float* inputBufferL, float* inputBufferR,
                                                                         float* outputL, float* outputR);  // BAI

}  // namespace mammon
