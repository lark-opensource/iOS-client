#pragma once

#include <cstdint>
#include "ae_defs.h"

class MAMMON_DEPRECATED_EXPORT SingScoring {
public:
    static SingScoring* create(int samplerate, int channels, const char* midi_filename, const char* lyric_filename);

    // int32_t* lyric_time_info:
    // Total of Sentences
    // Start time (in ms) of the 1st sentence
    // End time (in ms) of the 1st sentence
    // Start time (in ms) of the 2nd sentence
    // End time (in ms) of the 2nd sentence

    static SingScoring* create(int samplerate, int channels, const char* midi_filename, const int32_t* lyric_time_info);

    static void release(SingScoring* obj);

    typedef struct MIDI_DRAWING_DATA {
        int pitch;         // 0 = the bottom line of the drawing area, -1 = below the drawing area
        int32_t start;     // in ms
        int32_t duration;  // in ms
    } MIDI_DRAWING_DATA;

    virtual const MIDI_DRAWING_DATA* getMidiDrawingData(int32_t* items) const = 0;

    virtual void setTranspose(int transpose) = 0;

    // Force the song score to be the desired value
    virtual void setSongScore(double score) = 0;

    virtual void seek(double newPosInSec) = 0;

    virtual void process(float* in, float* out, int samples_in) = 0;

    virtual void getRealtimeMsg(char* msg, int size) = 0;

    typedef struct RealtimeInfo {
        double sentenceScore;        // Score of the last sentence (0~100)
        double songScore;            // Score till the current song position (0~100)
        double userPitch;            // MIDI pitch value of the detected Vocal (-1, 0.0~127.0)
        int userNote;                // MIDI Note value of the detected Vocal (-1, 0~127)
        int userCent;                // MIDI Note Cent of the detected Vocal (-50~+50)
        int userOctave;              // Octave offset of the detected Vocal (-9, +9)
        double userFrequency;        // Frequency of the detected Vocal (-1, 0.0~127.0)
        double refPitch;             // MIDI pitch value of the Reference MIDI (-1, 0.0~127.0)
        int refNote;                 // MIDI Note value of the Reference MIDI (-1, 0~127)
        int refCent;                 // MIDI Note Cent of the Reference MIDI (-50~+50)
        double refFrequency;         // Frequency of the Reference MIDI (-1, 0.0~127.0)
        int sentenceIndex;           // 0-Based Sentence-Index to identify the sentenceScore referring to.
        double actualSentenceScore;  // Actual Score of the last SentenceScore (0~100)
    } RealtimeInfo;

    virtual void getRealtimeInfo(RealtimeInfo* info) = 0;

public:
    virtual ~SingScoring(){};
};
