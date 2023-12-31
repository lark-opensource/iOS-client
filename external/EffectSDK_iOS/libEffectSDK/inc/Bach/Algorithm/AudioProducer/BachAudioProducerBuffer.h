#ifdef __cplusplus
#ifndef BACH_AUDIO_PRODUCER_BUFFER_H_
#define BACH_AUDIO_PRODUCER_BUFFER_H_

#include "Bach/Base/BachAlgorithmBuffer.h"

#include "Gaia/AMGPrimitiveVector.h"

#include <deque>

NAMESPACE_BACH_BEGIN

class AudioProducerBuffer : public BachBuffer
{
public:
    AudioProducerBuffer();
    ~AudioProducerBuffer() override;
    void appendAudioData(void *data, int length);
    float *getAudioData(int &length);
    void clear();
private:
    std::deque<float> m_audioBuffer;
    float *m_audioInput = nullptr;
};

NAMESPACE_BACH_END

#endif
#endif