//
// Created by chenyuezhao on 2019/4/22.
//

#pragma once

#include "ae_defs.h"

namespace mammon {
    class MAMMON_DEPRECATED Echo2 {
    public:
        Echo2(int sampleRate, float delayed_time_ms, float feedback, float wet, float dry);
        Echo2(int delayed_samples_number, float feedback, float wet, float dry);
        ~Echo2();

        void reset(int sampleRate, float delayed_time_ms, float feedback, float wet, float dry);
        void reset(int delayed_samples_number, float feedback, float wet, float dry);

        void process(float in, float* out);

        int getDelaySamples() const;
        void setDelaySamples(int spl);

        float getFeedback() const;
        void setFeedback(float p);

        float getWet() const;
        void setWet(float p);

        float getDry() const;
        void setDry(float p);

    private:
        int delayed_samples_number;
        float feedback, wet, dry;

        float* buf_base;
        int buf_len;
        int write_index;
    };
}  // namespace mammon
