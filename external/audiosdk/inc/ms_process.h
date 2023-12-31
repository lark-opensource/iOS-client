/* -*- c-basic-offset: 4 indent-tabs-mode: nil -*-  vi:set ts=8 sts=4 sw=4: */
/* chuangzeng Huang */
/* Audio Effect Library */

#pragma once
#include "ae_defs.h"

namespace mammon {
    class MAMMON_EXPORT MsProcess {
    public:
        MsProcess(int ch, int weightId = -1);
        ~MsProcess();
        /* in and out buffer are in interleaved data format. */
        void process(const float* in, float* out, int samplePerCh);
        void updateMsWeight(int WeightId);
        void reset();

    private:
        int m_ch;
        int m_weigthId;
        float m_weightM;
        float m_weightS;
    };
}  // namespace mammon