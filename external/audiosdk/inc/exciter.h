#pragma once

#include <math.h>
#include "ae_defs.h"

namespace mammon {

    //**********************************************************************************
    /* USAGE:
    // Initialize exciter module and set parameters
    Exciter singing_exciter;
    singing_exciter.setExciter(6.0f, 1000, 48000);

    reverb3_t * 	reverb3; // Can be replaced by any kind of reverb
    reverb3 = reverb3New(samplerate, 3000.0f, 50.0f, 1.0f, 0.7f, 50.0f, 0.8f, 0.5f, 0.5f);
    reverb3Reset(reverb3);

    double			dur;
    clock_t 		start, end;

    start = clock();

    while (!feof(fp))//判断文件的打开状态
    {
    fread(psTest, 1, 2 * numChannel, fp);//将原文件的数据循环读入缓冲区中
    input = ((float)(int)(psTest[0])) / (float)32768; // Mono original input
    singing_exciter.process_mono(&input, &outbuffer[0]); // Mono exciter output is stored in outbuffer[0]

    reverb3Process(reverb3, input, &outbuffer[2], &outbuffer[3]); //Stereo reverb outputs are stored in outbuffer[2],
    outbuffer[3]

    // Final output = "original input" + "exciter output" + left/right "reverb output"
    outbuffer[1] = input + outbuffer[0] + outbuffer[3] * 0.5f;
    outbuffer[0] = input + outbuffer[0] + outbuffer[2] * 0.5f;

    psTest[0] = (short)((int)(fmin((fmax(outbuffer[0], -0.99f)), 0.99f) * (float)32768));
    psTest[1] = (short)((int)(fmin((fmax(outbuffer[1], -0.99f)), 0.99f) * (float)32768));
    fwrite(psTest, 1, 4, fp_cut);			//将从原文件中读取到的数据写入到截取文件中
    }
    */

    class MAMMON_DEPRECATED_EXPORT Exciter {
    public:
        Exciter();
        ~Exciter();

        //******************************************************************************
        // Set parameters for the exciter module. "mixgaindb" corresponds to the amount of energy for the harmonic
        // signals added to the original, "highpassfreq" determins from which frequency and above the harmonics are
        // generated. Input:
        //       mixgaindb:    mix gain of the hamonic signal, [-100, 12] in dB, defalut 0.0 dB
        //       highpassfreq: cut-off frequency for the high pass filter when generating the homonic component, [100,
        //       sampling rate],
        //                     default 1000 Hz
        //       samplerate:   sampling rate of the processed audio, [8000, 96000] in Hz
        void setExciter(float mixgaindb, int highpassfreq, int samplerate);

        //******************************************************************************
        // reset state
        void reset();

        //******************************************************************************
        // Process mono input audio, each time processes one sample. Interleaved multi-channel audio is NOT supported.
        // Input:
        //       input:        pointer to the input audio sample
        //       output:       pointer to the output audio sample
        void process_mono(float* input, float* output);

        //******************************************************************************
        // Process stereo input audio, each time processes one sample for each channel. Interleaved multi-channel audio
        // is NOT supported. Input:
        //       inputL:       pointer to the input left-channel audio sample
        //       inputR:       pointer to the input right-channel audio sample
        //       outputL:      pointer to the output left-channelaudio sample
        //       outputR:      pointer to the output right-channelaudio sample
        void process_stereo(float* inputL, float* inputR, float* outputL, float* outputR);

        // void setReverbPara(int srate, float maxroomsize, float roomsize,
        //	float revtime, float damping, float spread,
        //	float inputbandwidth, float earlylevel, float taillevel);
        // void setCompressorPara(const int framelen, const float thresholds[2], const float multipliers[2], float
        // attack_seconds, float release_seconds); void setLowpassParam(); void setHighpassParam(); void
        // setRemoveDcParam(); void highpass(float *input, float *output); void lowpass(float *input, float *output);
        // void removedc(float *input, float *output);
        // Process the input audio with a compressor
        // void compressor_mono(float* output);
        // static inline float compressor_clamp(float v, float min, float max) { return min > v ? min : (v > max ? max :
        // v); }

    private:  // save state for reset usage only
        float pre_mixgaindb;
        int pre_highpassfreq;
        int pre_samplerate;

    private:
        float a0, b1;
        float temp1, temp2;
        float tempIn;
        float tempOut1, tempOut2;

        int sample_rate;       // sampling rate
        float excitationGain;  // [0, Inifnity], default 1.0f
        int highpassFreq;      // Cut-off frequency for high pass filter

        //******************************************************************************
        void init();
        void setHighpassFilter(int cutoffFreq, int sampleFreq);
        void free();
        void highpass_filter(float* input, float* output, float* temp);
        void harmonic_generator(float* input, float* output);
        template <typename T>
        int sgn(T val) {
            return (T(0) < val) - (val < T(0));
        }

        inline float db2lin(float db) {  // dB to linear
            return powf(10.0f, 0.05f * db);
        }

        // double x1_hp, x2_hp; // Data used for processing 2nd order IIR
        // double x1_lp, x2_lp; // Data used for processing 2nd order IIR
        // double x1_rd, x2_rd; // Data used for processing 2nd order IIR
        // double y1_hp, y2_hp; // Data used for processing 2nd order IIR
        // double y1_lp, y2_lp; // Data used for processing 2nd order IIR
        // double y1_rd, y2_rd; // Data used for processing 2nd order IIR

        // float b1_hp, b2_hp; // Coef used for processing 2nd order IIR
        // float b1_lp, b2_lp; // Coef used for processing 2nd order IIR
        // float b1_rd, b2_rd; // Coef used for processing 2nd order IIR
        // float a1_hp, a2_hp; // Coef used for processing 2nd order IIR
        // float a1_lp, a2_lp; // Coef used for processing 2nd order IIR
        // float a1_rd, a2_rd; // Coef used for processing 2nd order IIR

        // reverb3_t * 	reverb3;
        //
        // bool  compressorOn;   // True - use DRC before harmonic generation;
        //                      // False - no DRC
        //// Data used for compressor / limiter
        // float compressor_last_samples[2];
        // float compressor_thresholds[2];
        // float compressor_multipliers[2];
        // float compressor_factor;
        // float compressor_attack_per1ksamples;
        // float compressor_release_per1ksamples;

        // int compressor_samplerate;
        // int compressor_framelen;
    };

}  // namespace mammon