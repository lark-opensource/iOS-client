/* -*- c-basic-offset: 4 indent-tabs-mode: nil -*-  vi:set ts=8 sts=4 sw=4: */

/* Audio Effect Library */

#pragma once

#include <math.h>
#include <cmath>
#include "ae_audio_cleaner.h"
#include "ae_defs.h"

#define AC_NUM_MICS 2

class FilterNLMS;
class AudioLogger;
struct COMPLEX_s;

namespace mammon {
    class Transform;
}

class MAMMON_DEPRECATED_EXPORT AudioCleaner {
public:
    // Now use 320 sample audio input, which will be transformed to 512*36(bin*band) in frequency domain to get enough
    // frequency resolution to denoise music input(It seems MDFT_32X32X12 is not enough for music denoise processing).
    AudioCleaner(int sampleRate, mammon::TransformType nTransformType = mammon::TransformType::MDFT_512X320X36,
                 bool music_mode = true, bool bAGC = true, bool bANS = true, bool bAEC = false, bool blimiter = true,
                 bool bHighNoiseMode = false, bool bBeam = false);
    ~AudioCleaner();

    // Only accept this size (per channel) in Process* API!
    int GetBlockSize() const;

    // Process a block with given echo reference (corrupts pfRef)
    // one mic, pre-processing in in-place way when recording.
    void Process(float* pfInOut, float* pfRef, bool bForceOff = false);
    // two mic, pre-processing in in-place way when recording
    void Process(float* pfInOut, float* pfIn2, float* pfRef, bool bForceOff = false);
    // extra mic to form master-slave physical structure.
    void Process(float* pfInOut, AudioCleaner& Master);
    // One-channel wave post-processing in out-of-place way, now mainly for gain adjusting and noise suppresion.
    void ProcessPost(float* pfIn, float* pfOut);
    void AnalyseInput(float* pfInOut, float* pfRef, bool bForceOff = false);
    void ProcessGroup(AudioCleaner** pCleaners, float* pfInOut, int nCleaners);

    // Individual processing stages
    void CleanInput(float* pfInOut);
    void CalcMixerControl(float* pfIn);
    void PredictEcho(const float* pfRefBands);
    void CalcSpatial(bool bDualInput);
    void CalcInputLevels(const float* pfMicBands);
    void UpdateVAD(float fTalkSum, bool bForceOff);
    void UpdateEcho(float* pfTarget);
    void CalcGains(float* pfPower, float* pfNoise, float* pfEcho, float fVADFade, int nTalkHold);
    void CalcOutputLevels(float* pfNoise, float* pfEcho);
    void CalcLimiter(float fOutLevel);
    void AddComfort(const float* pfPower, float* pfNoise);
    void CalcFlux(float* pfPower, float* pfOldPower, float* pfBeamGains, int nDTalkHold);
    void UpdateVoiceLevel(float fOutLevel, int nTalkHold, int nTalkCount, int nFluxCount);
    void UpdateAGC(float fVoiceLevel);
    void MicForwardTransform(float* pfInOut);
    void RefForwardTransform(float* pfRef);
    void MicReverseTransform(float* pfInOut);
    void ApplyBandGains(float* pfGains);
    void ApplyGain(float fGain);

    // Helper routines
    void CalcCoefficients(float fBlockTime);
    void CalcVADTail();
    void UpdateLevels(float fOldGain, float fNewGain);
    void Reset();

    // Algorithm control methods
    void ForceUpdate(int n = 50);  // Forces echo adaption update for a number of blocks
    void HardForce(int n = 50) {
        m_nForce = n;
    };  // Forces echo adaption update for a number of blocks (ignores reference level)
    void SetNoise(bool bOn = true) {
        m_bNoise = bOn;
    };  // Enable the noise reduction
    void SetEcho(bool bOn = true) {
        m_bEcho = bOn;
    };  // Enable the echo suppression
    void SetBeam(bool bOn = true) {
        m_bBeam = bOn;
    }  // Enable spatial noise reduction
    void SetBeamSteer(float fSteer) {
        m_fBeamSteer = (float)M_PI * fSteer / 180.0F;
    }                             // Set beam steer angle (in degrees [-90, 90]);
    void SetVAD(int nState = 1);  // Set the VAD fade out style: 0 off, 1 soft, 2 hard
    void SetLimiter(bool bOn = true) {
        m_bLimiter = bOn;
    };                                                 // Enable the limiter
    void SetAGC(bool bOn = true, float fGain = 0.0F);  // Enable the AGC and set the AGCGain if != 0.0F
    void SetComfort(bool bOn = true) {
        m_bComfort = bOn;
    };  // Enable the Comfort noise
    void SetFluxControl(bool bOn = true) {
        m_bFlux = bOn;
    };                                      // Enable spectral flux detection
    void SetAudioLogging(bool bOn = true);  // Enable audio logging
    void SetHighNoiseMode(bool bOn = true) {
        m_bHighNoiseMode = bOn;
    };  // Enable high noise mode (reduced talk sensitivity)
    void SetOwnerId(unsigned int oid) {
        m_nOwnerId = oid;
    }  // Set OwnerID

    // State retrieval methods
    bool VAD() {
        return m_nDTalkHold > 0;
    };  // True when last block contained local signal
    float InLevel() {
        return 10 * std::log10(m_fInLevel + 1e-10F);
    };  // Most recent input level - dB
    float OutLevel() {
        return 10 * std::log10(m_fOutLevel + 1e-10F);
    };  // Most recent output level - dB
    float RefLevel() {
        return 10 * std::log10(m_fRefLevel + 1e-10F);
    };  // Most recent reference level - dB
    float VoiceLevel() {
        return 10 * std::log10(m_fVoiceLevel + 1e-10F);
    };  // Estimated average voice (local) level - dB
    float VoiceLevelTemp() {
        return 10 * std::log10(m_fVoiceLevelTemp + 1e-10F);
    };  // Temporary estimate of average voice (local) level - dB
    float NoiseLevel() {
        return 10 * std::log10(m_fNoiseLevel + 1e-10F);
    };  // Estimated average noise level - dB
    float EchoLevel() {
        return 10 * std::log10(m_fEchoLevel + 1e-10F);
    };  // Estimated average echo path level (only valid when EchoLevel*pfRef > NoiseLevel)
    float AGCGain() {
        return 20 * std::log10(m_fAGCGain + 1e-10F);
    };  // The current gain being applied by the AGC - dB
    int MixerControl() {
        return m_nMixerState;
    };  // Returns the requested mixer action, -1 = Turn mixer down, 1 = Turn mixer up, 0 = Do nothing
    float ClipLevel() {
        return m_fClipLevel;
    };  // Returns the current clipping level
    float TalkLevel() {
        return m_fTalkSum;
    };  // Returns the current talk sum level
    float SpectralFlux() {
        return m_fSpectralFlux;
    }  // Strength of spectral flux
    int SpectralFluxCount() {
        return m_nSpectralFluxCount;
    }  // Maximum spectral flux in the current talk burst
    float FluxFloor() {
        return 20 * std::log10(m_fFluxFloor + 1e-10F);
    }  // Floor of spectral flux
    float FluxSmooth() {
        return 20 * std::log10(m_fFluxSmooth + 1e-10F);
    }  // Smoothed spectral flux
    float Flux() {
        return 20 * std::log10(m_fFlux + 1e-10F);
    }  // Instantaneous flux
    int Force() {
        return m_nForce;
    };  // Return current value of the force counter
    bool AudioLogging() {
        return m_pLogIn != NULL;
    };  // Return true if we are currently logging audio
    float BandGain(int nBand) {
        return m_pfGains[nBand];
    };  // Return the current gain of the specified band
    float BeamGain(int nBand) {
        return m_pfBeamGains[nBand];
    };  // Return the current beamformer gain of the specified band
    float BandNoise(int nBand) {
        return m_pfNoise[nBand];
    };  // Return the current noise in the specified band
    float BandPower(int nBand) {
        return m_pfPower[nBand];
    };  // Return the current power in the specified band
    bool AGC() {
        return m_bAGC;
    };
    int TalkHold() {
        return m_nDTalkHold;
    };
    float LimiterGain() {
        return m_fLimitGain;
    };
    float* Echo() {
        return m_pfEcho;
    };
    float* Noise() {
        return m_pfNoise;
    };
    float* Power() {
        return m_pfPower;
    };
    float* Gains() {
        return m_pfGains;
    };
    const float* MicPower();

    void LogOut(float* pfOut);
    void DumpAudio();

    // Parameter retrieval methods
    int BlockSize() {
        return m_nBlockSize;
    };  // Samples to pass in for each call
    int Bands() {
        return m_nBands;
    };                          // Number of bands used in analysis
    float BandFreq(int nBand);  // Get centre frequency of a band
    int SampleRate() {
        return m_nSampleRate;
    };               // Get sample rate
    float Stride();  // Get transform stride - seconds
    int Latency();   // Get transform latency in samples

    // EQ post-processing
    void postProcessEq(int sampleRate, float* pIn, float* pOut, int smplCnt);

protected:
    // Transforms and local storage for parameters retrieved from transform
    mammon::Transform* m_pMicTransform[AC_NUM_MICS];
    mammon::Transform* m_pRefTransform;
    int m_nBlockSize, m_nBands, m_nSampleRate;

    // Normalized LMS adaptive filter for echo prediction
    FilterNLMS* m_pEchoFilter;

    // Flags to control various parts of the algorithm
    bool m_musicMode;
    bool m_bNoise, m_bEcho, m_bLimiter, m_bAGC;
    bool m_bComfort, m_bFlux, m_bHighNoiseMode;
    bool m_bBeam;
    int m_nVAD;
    bool m_bProcessInit;
    float m_fBeamSteer;

    // State variables for banded signal power estimates
    float *m_pfPower, *m_pfOldPower, *m_pfNoise, *m_pfEcho, *m_pfEchoTarget;
    float* m_pfComfortLevel;
    COMPLEX_s* m_pcCrossCorr;

    // Counters for controlling double talk or VAD frames
    int m_nDTalkHold, m_nDTalkCount;

    // Counters for controlling adaptation of the echo suppressor
    int m_nRefSilent, m_nForce, m_nNextForce;

    // Signal levels calculated for monitoring
    float m_fVoiceLevel, m_fVoiceLevelTemp, m_fNoiseLevel, m_fEchoLevel;
    float m_fInLevel, m_fOutLevel, m_fRefLevel, m_fTalkSum;

    // Storage for calculated gains
    float *m_pfGains, *m_pfOldNoiseGains, *m_pfNoiseGains, *m_pfEchoGains, *m_pfBeamGains, *m_pfGainsTemp,
        *m_pfRegKernel, *m_pfConvOut;
    float m_fAGCGain, m_fLimitGain;

    // State variables for the mixer control
    int m_nMixerHoldCount, m_nMixerState;
    float m_fClipLevel;

    // State variables used in the spectral flux calculation
    float m_fSpectralFlux, m_fFlux, m_fFluxFloor, m_fFluxSmooth;
    int m_nSpectralFluxCount;

    // Algorithm coefficients, set based on transform parameters
    float m_fTalkStart, m_fTalkCont, m_fEchoMu;
    float m_fNoiseAlpha, m_fEchoAlpha, m_fVoiceAlpha, m_fLevelAlpha;
    float m_fClipLevelAlpha, m_fFluxSmoothAlpha, m_fFluxFloorDownAlpha, m_fFluxFloorUpAlpha;
    float m_fNoiseGrow, m_fNoiseDecay;
    float m_fAGCCut, m_fAGCBoost;
    int m_nEchoLength, m_nRefFirstForce, m_nRefBreak, m_nRefForce, m_nVoiceStart, m_nVoiceEnd;
    int m_nFluxMinBand, m_nFluxMaxBand, m_nFluxCountThresh;
    int m_nTalkHold, m_nTalkFlat, m_nTalkChad;
    int m_nBeamMaxBand;
    float* m_pfPowerAlpha;
    float* m_pfDecay;

    // Fade out coefficients for VAD
    float* m_pfVADFade;

    // state buffer for EQ post processing to compensate the timer
    float* m_pfTemp;
    float* m_xStr;
    float** m_yStr;

    // Audio logger storage and ID for this instance
    unsigned int m_nOwnerId;
    AudioLogger *m_pLogIn, *m_pLogRef, *m_pLogOut;
};
