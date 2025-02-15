/* -*- c-basic-offset: 4 indent-tabs-mode: nil -*-  vi:set ts=8 sts=4 sw=4: */

/* Audio Effect Library */

#pragma once

#include <sys/types.h>
#include <map>
#include <vector>

namespace mammon {

    class StretchCalculator {
    public:
        StretchCalculator(size_t sampleRate, size_t inputIncrement, bool useHardPeaks);
        virtual ~StretchCalculator();

        /**
         * Provide a set of mappings from "before" to "after" sample
         * numbers so as to enforce a particular stretch profile.  This
         * must be called before calculate().  The argument is a map from
         * audio sample frame number in the source material to the
         * corresponding sample frame number in the stretched output.
         */
        void setKeyFrameMap(const std::map<size_t, size_t>& mapping);

        /**
         * Calculate phase increments for a region of audio, given the
         * overall target stretch ratio, input duration in audio samples,
         * and the audio curves to use for identifying phase lock points
         * (lockAudioCurve) and for allocating stretches to relatively
         * less prominent points (stretchAudioCurve).
         */
        std::vector<int> calculate(float ratio, size_t inputDuration, const std::vector<float>& lockAudioCurve,
                                   const std::vector<float>& stretchAudioCurve);

        /**
         * Calculate the phase increment for a single audio block, given
         * the overall target stretch ratio and the block's value on the
         * phase-lock audio curve.  State is retained between calls in the
         * StretchCalculator object; call reset() to reset it.  This uses
         * a less sophisticated method than the offline calculate().
         *
         * If increment is non-zero, use it for the input increment for
         * this block in preference to m_increment.
         */
        int calculateSingle(float ratio, float curveValue, size_t increment = 0);

        void setUseHardPeaks(bool use) {
            m_useHardPeaks = use;
        }

        void reset();

        void setDebugLevel(int level) {
            m_debugLevel = level;
        }

        struct Peak {
            size_t chunk;
            bool hard;
        };
        std::vector<Peak> getLastCalculatedPeaks() const {
            return m_peaks;
        }

        std::vector<float> smoothDF(const std::vector<float>& df);

    protected:
        std::vector<Peak> findPeaks(const std::vector<float>& audioCurve);

        void mapPeaks(std::vector<Peak>& peaks, std::vector<size_t>& targets, size_t outputDuration, size_t totalCount);

        std::vector<int> distributeRegion(const std::vector<float>& regionCurve, size_t outputDuration, float ratio,
                                          bool phaseReset);

        void calculateDisplacements(const std::vector<float>& df, float& maxDf, float& totalDisplacement,
                                    float& maxDisplacement, float adj) const;

        size_t m_sampleRate;
        size_t m_blockSize;
        size_t m_increment;
        float m_prevDf;
        float m_divergence;
        float m_recovery;
        float m_prevRatio;
        int m_transientAmnesty;  // only in RT mode; handled differently offline
        int m_debugLevel;
        bool m_useHardPeaks;

        std::map<size_t, size_t> m_keyFrameMap;
        std::vector<Peak> m_peaks;
    };

}  // namespace mammon
