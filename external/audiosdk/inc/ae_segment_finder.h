//
// Created by william on 2020/2/21.
//

#pragma once
#include <memory>

namespace mammon {
    class SegmentFiner {
    public:
        explicit SegmentFiner(int target_sr, int segment_sr);

        /**
         * process segment audio frame
         */
        int processSegment(const float* data, int num_frames);

        /**
         * process target audio frame
         */
        int processTarget(const float* data, int num_frames);

        /**
         * returns the start time(s) of audio segment
         */
        float calcSegmentStartTime();

        /**
         * returns the feature difference between target and segment
         */
        float getFeatureDiff() const;

        /**
         * calls to determine whether the result of calcSegmentStartTime is reliable
         */

        bool isReliableResult() const;

        /**
         * reset internal states
         */
        void reset();

    private:
        class Impl;
        std::shared_ptr<Impl> impl_;
    };

}  // namespace mammon
