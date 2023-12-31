/* -*- c-basic-offset: 4 indent-tabs-mode: nil -*-  vi:set ts=8 sts=4 sw=4: */

/* Audio Effect Library */

#pragma once

namespace mammon {
    class AllPassFilter {
    public:
        AllPassFilter();
        // need to inline processing function for efficiency.
        inline float process(float in);
        void initBuf(float* buf, int size);
        void resetBuf();
        void setFeedback(float fdbk);
        float getFeedback();

    private:
        // ptr is used for reallocate the buffer
        float* m_buffer;
        int m_bufSize;
        int m_bufIdx;
        float m_feedback;
    };

    inline float AllPassFilter::process(float in) {
        float out = m_buffer[m_bufIdx];
        m_buffer[m_bufIdx] = in + out * m_feedback;

        if(++m_bufIdx >= m_bufSize) { m_bufIdx = 0; }
        return out - in;
    }

    class CombFilter {
    public:
        CombFilter();
        // need to inline comb processing function for low complexity
        inline float process(float in);
        void initBuf(float* buf, int size);
        void resetBuf();
        void setDamp(float damp);
        float getDamp();
        void setFeedback(float fdbk);
        float getFeedback();

    private:
        float* m_buffer;
        int m_bufSize;
        int m_bufIdx;
        float m_store;
        float m_hfDamping;
        float m_feedback;
    };

    inline float CombFilter::process(float in) {
        float out = m_buffer[m_bufIdx];

        m_store = out * (1 - m_hfDamping);
        m_buffer[m_bufIdx] = in + m_store * m_feedback;
        if(++m_bufIdx >= m_bufSize) { m_bufIdx = 0; }
        return out;
    };

}  // namespace mammon