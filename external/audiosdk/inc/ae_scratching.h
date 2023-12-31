#pragma once
#include "ae_defs.h"

namespace mammon {

    class ScratchingImpl;

    class MAMMON_EXPORT AudioScratching {
    public:
        AudioScratching(int channels, int samplerate, int quality = 0, double min_ratio = 0.1, double max_ratio = 10.0);
        ~AudioScratching();

        /*
         *  @param:
         *      ratio: ratio for audio's speed
         *  @return
         *      true if ratio updated else false
         */
        bool setRatio(double ratio);

        /*
         *  @param
         *      src: planar pointer to input audio stream
         *      dst: planar pointer to output audio stream
         *      samples: number of samples per channel in src
         *  @return
         *      number of samples per channel in dst
         */
        int process(const float* const* src, float* const* dst, int samples);

        void reset();

    protected:
        ScratchingImpl* impl_;
    };

}  // namespace mammon
