#ifdef __cplusplus
#ifndef BACH_PET_MATTING_BUFFER_H
#define BACH_PET_MATTING_BUFFER_H

#include "Bach/Base/BachAlgorithmBuffer.h"

#include "Gaia/AMGPrimitiveVector.h"

NAMESPACE_BACH_BEGIN

class BACH_EXPORT PetMattingInfo : public AmazingEngine::RefBase
{
public:
    int maskCount;
    int maskWidth;
    int maskHeight;
    AmazingEngine::UInt8Vector mask0;
    AmazingEngine::UInt8Vector mask1;
};

class BACH_EXPORT PetMattingBuffer : public BachBuffer
{
public:
    AmazingEngine::SharePtr<PetMattingInfo> m_petMattingInfo;
};

NAMESPACE_BACH_END
#endif
#endif