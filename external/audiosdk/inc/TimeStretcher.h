/* -*- c-basic-offset: 4 indent-tabs-mode: nil -*-  vi:set ts=8 sts=4 sw=4: */

/* Audio Effect Library */

#pragma once

#include <cstddef>
#include <map>
#include <vector>
#include "ae_defs.h"

/**
 * @mainpage mammon
 *
 * The TimeStretcher API is contained in the single class
 * mammon::TimeStretcher.
 */

namespace mammon {

    class MAMMON_EXPORT TimeStretcher {
    public:
        TimeStretcher(int32_t samplerate, int32_t channels);
        virtual ~TimeStretcher();

        bool setScale(double scale);
        bool setReservingPitch(bool reservingPitch);

        void reset();

        void setMaxProcessSize(size_t samples);

        double getScale() const;
        bool getReservingPitch() const;

        int32_t getLatency() const;

        bool process(const float* const* input, int32_t samples, bool final);

        int32_t available() const;

        int32_t retrieve(float* const* output, int32_t samples) const;

        class Impl;

    protected:
        Impl* m_d_;

        int32_t samplerate_;
        int32_t channels_;

        double scale_;
        bool reservingPitch_;

        int module_;

        void determineModule();
    };

}  // namespace mammon
