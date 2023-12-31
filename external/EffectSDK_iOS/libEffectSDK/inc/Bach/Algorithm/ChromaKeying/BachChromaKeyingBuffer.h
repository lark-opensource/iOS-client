#ifdef __cplusplus
#ifndef BACH_CHROMA_KEYING_BUFFER_H
#define BACH_CHROMA_KEYING_BUFFER_H

#include "Bach/Base/BachAlgorithmBuffer.h"

#include "Gaia/AMGPrimitiveVector.h"
#include "Gaia/AMGSharePtr.h"

NAMESPACE_BACH_BEGIN

class BACH_EXPORT ChromaKeyingInfo : public AmazingEngine::RefBase
{
public:
    int width = 0;
    int height = 0;
    unsigned char color_b = 0;
    unsigned char color_g = 0;
    unsigned char color_r = 0;
    AmazingEngine::UInt8Vector mask_data;
    int color_h = 0;
    int keying_similar = 0;
};

class BACH_EXPORT ChromaKeyingBuffer : public BachBuffer
{
public:
    AmazingEngine::SharePtr<ChromaKeyingInfo> m_chromaKeying;
};

NAMESPACE_BACH_END
#endif
#endif