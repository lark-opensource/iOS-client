#ifdef __cplusplus
#ifndef BACH_SKY_SEG_BUFFER_H
#define BACH_SKY_SEG_BUFFER_H

#include "Bach/Base/BachAlgorithmBuffer.h"

#include "Gaia/AMGPrimitiveVector.h"

NAMESPACE_BACH_BEGIN

class BACH_EXPORT SkyResult : public AmazingEngine::RefBase
{
public:
    int width = 0;
    int height = 0;
    int channels = 0;
    AmazingEngine::UInt8Vector mask_data;
    bool hasSkyResult = false;
};

class BACH_EXPORT SkySegBuffer : public BachBuffer
{
public:
    AmazingEngine::SharePtr<SkyResult> m_skyInfo;
};

NAMESPACE_BACH_END
#endif
#endif