#pragma once

#include "ae_defs.h"
/*
 *
 * CherEffect* cher = CherEffect::create(44100,2);
 *
 * cher->assign_midi("./somemidifile.mid"); // optional
 * cher->setupMajor("Gb"); // optional
 *
 * bool c_major[] = {1,0,1,0,1,1,0,1,0,1,0,1};
 * cher->setupMatrixCDEFGAB(c_major); // optional
 *
 * float audio_in[SIZE*channels];
 * float audio_out[SIZE*channels];
 *
 * while (!eof(audio_file, audio_in))
 * {
 *      cher->process(audio_in, audio_out, SIZE);
 * }
 *
 * CherEffect::release(cher);
 *
 * Hint: parameter name is recommended to be used in kv pair. such as:
 * midifile:./some.mid
 * new_pos_in_ms:/3456
 * major:Bb
 * matrix:100100100100
 *
 * If input_for_determine_major is filename, will call determineMajor
 */

#include <stdint.h>

namespace mammon {

    class MAMMON_DEPRECATED_EXPORT CherEffect {
    public:
        // mixLR: While set to false, L/R is processed separately. Use false with care.
        // For KTV and most cases, mixLR is preferred to be true
        static CherEffect* create(int samplerate, int channels, bool mixLR);

        static void release(CherEffect* cher);

        static void determineMajor(char* matrix, int samplerate, int channels, float* input_for_determine_major,
                                   int samples, bool mixLR);

        // Must be set before the first call to process
        virtual bool assignMidi(const char* midifile) = 0;

        // If midi setup during process, must seek to the play position of host
        virtual void seekTo(double new_pos_in_ms) = 0;

        // If the input is not in 440, you can overwrite this value here
        virtual void setARef(double aref) = 0;

        // major: "N/A", "C", "Db", "D", "Eb", "E", "F", "Gb", "G","Ab","A", "Bb", "B"
        //"N/A": use speech matrix
        // Full format:
        // "Am" = "C",  "Gm" = "Bb"
        // "M110011001100" = setupMatrixCDEFGAB();
        // "Am;Aref:410" = "C"; setARef(410);
        virtual void setupMajor(const char* major) = 0;

        // for Speech: {1,0,0,0,1,0,0,0,1,0,0,0};
        virtual void setupMatrixCDEFGAB(bool* matrix) = 0;

        // Discard the first N samples to make perfect alignment with other audio tracks
        virtual int getPDCSamples() = 0;

        virtual void process(float* in, float* out, int samples_in) = 0;

        virtual void process(float** in, float** out, int samples_in) = 0;

        // eturn (-1, +1) : pitch down ~ up over 1 semitone
        // channel: -1 will return the stronger value among all channels
        virtual float getCorrectionStrength(int channel) = 0;

        // Detect mode will not generate output audio if adapting is false
        virtual void enableDetectMode(bool detect_on, bool adapting) = 0;

        // Get the detected result form enableDetectMode
        // scale: scale matrix with weights, NULL = Major scale
        // Return: Key in integer, 0 = N/A, 1 = C, ...
        // keyname: Key in String, "N/A", "C", etc ...
        // full: the result string that can be used in setupMajor
        virtual int getDetectedMatrix(char* full, char* keyname, bool* matrix, double* aref, int* scale) = 0;

        virtual void resetMatrixDetectResult() = 0;

        virtual ~CherEffect(){};
    };
};  // namespace mammon
