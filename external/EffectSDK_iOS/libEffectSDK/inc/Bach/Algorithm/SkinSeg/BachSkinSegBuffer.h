#ifdef __cplusplus
#ifndef BACH_SKIN_SEG_BUFFER_H
#define BACH_SKIN_SEG_BUFFER_H

#include "Bach/Base/BachAlgorithmBuffer.h"

#include "Gaia/AMGPrimitiveVector.h"

NAMESPACE_BACH_BEGIN

class BACH_EXPORT SkinSegInfo : public AmazingEngine::RefBase
{
public:
    int width;
    int height;
    float reflector;
    AmazingEngine::UInt8Vector mask_data;
};

class BACH_EXPORT SkinSegBuffer : public BachBuffer
{
public:
    AmazingEngine::SharePtr<SkinSegInfo> m_skinSegInfo;
};

NAMESPACE_BACH_END
#endif
#endif