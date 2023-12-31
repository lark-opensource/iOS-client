/* -*- c-basic-offset: 4 indent-tabs-mode: nil -*-  vi:set ts=8 sts=4 sw=4: */

/* Audio Effect Filter Library */

#include "ae_defs.h"

/**
 * @mainpage AudioEffectChoir
 *
 * The AudioEffectChoir API is contained in the single class
 * mammon::AudioEffectChoir to simulate the delay modulation-based chorus effect.
 */
namespace mammon {
// Adjust the maximum number of modulation delay path if more chorus effects needed.
#define MAX_DELAY_PATHS 4

    class MAMMON_DEPRECATED AudioEffectChoir {
    public:
        typedef struct choirParam_s {
            float gainIn;
            float gainOut;
            float delay[MAX_DELAY_PATHS];
            float decay[MAX_DELAY_PATHS];
            float vibrato[MAX_DELAY_PATHS];
            float depth[MAX_DELAY_PATHS];
            int modulation_type[MAX_DELAY_PATHS];
        } choirParam;

        AudioEffectChoir(int sampleRate, size_t channels, choirParam* choirset, int delayPaths = 1);
        ~AudioEffectChoir();
        // process in de-interleaved format
        void process(float** inBuff, float** outBuff, const int samplesPerCh);

    private:
        int m_sampleRate;
        int m_ch;
        int m_num_delays;
        int m_cnt;  // process samples counter
        // Two ways of delay modulations: sine(0) and triangle wave(1)
        int m_modulation[MAX_DELAY_PATHS];
        int m_phase[MAX_DELAY_PATHS];
        float m_gainIn, m_gainOut;
        float m_delay[MAX_DELAY_PATHS];    //
        float m_decay[MAX_DELAY_PATHS];    // decay volume
        float m_vibrato[MAX_DELAY_PATHS];  // modulation speed
        float m_depth[MAX_DELAY_PATHS];    // Being modulated delay
        int m_samples[MAX_DELAY_PATHS], m_samplesDepth[MAX_DELAY_PATHS];
        int m_maxSamples;
        int m_length[MAX_DELAY_PATHS];
        float* m_wavTab[MAX_DELAY_PATHS];  // the pre-calculated modulation wave table
        float* m_delayBuf;                 // delayed buffer
    };
}  // namespace mammon
